from uuid import UUID

from src.modulos.acceso_roles.dominio.puertos import RepositorioSupervisores, RepositorioTecnicos, RepositorioUsuarios
from src.modulos.ordenes_trabajo.aplicacion.crear_ot import DescripcionDePasoInvalida, FechasInvalidas, HorasInvalidas, PasoSolicitado, PrioridadInvalida, SinPasoPM01, crear_ot
from src.modulos.ordenes_trabajo.dominio.puertos import RepositorioOrdenesTrabajo
from src.modulos.ubicaciones_tecnicas.dominio.puertos import RepositorioUbicacionesTecnicas

from ..dominio.modelos import Aviso, FilaOT, ResultadoImportacion
from ..dominio.reglas import fecha_de, niveles_de_ubicacion, normalizar, numero_de, si_o_no

TIPOS = ("OE01", "OE02", "OE03", "OE04")
CLAVES = ("PM01", "PMNN")


class OTInvalida(Exception):
    def __init__(self, fila: int, motivo: str):
        super().__init__(motivo)
        self.fila = fila
        self.motivo = motivo


def _agrupar(filas: list[FilaOT]) -> dict[str, list[FilaOT]]:
    """Las filas con el mismo número de OT, en el orden en que aparecen"""
    ots: dict[str, list[FilaOT]] = {}
    for fila in filas:
        ots.setdefault(fila.ot.strip(), []).append(fila)
    return ots


def _paso(fila: FilaOT) -> PasoSolicitado:
    clave = fila.clave.strip().upper()
    if clave not in CLAVES:
        raise OTInvalida(fila.fila, f"Clave desconocida: {fila.clave or 'vacía'} (use PM01 o PMNN)")
    if not fila.descripcion_paso.strip():
        raise OTInvalida(fila.fila, "Falta la descripción del paso")
    horas = numero_de(fila.horas)
    if fila.horas.strip() and horas is None:
        raise OTInvalida(fila.fila, f"Las horas no son un número: {fila.horas}")
    return PasoSolicitado(descripcion=fila.descripcion_paso.strip(), clave_control=clave, horas_planificadas=horas)


def importar_ots(
    filas: list[FilaOT],
    supervisor_usuario_id: UUID,
    repositorio_ots: RepositorioOrdenesTrabajo,
    repositorio_ubicaciones: RepositorioUbicacionesTecnicas,
    repositorio_tecnicos: RepositorioTecnicos,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_usuarios: RepositorioUsuarios,
    resultado: ResultadoImportacion | None = None,
) -> ResultadoImportacion:
    """Supervisor: crea las OT de la tabla para los técnicos de su grupo, con las mismas reglas que al
    crearlas en la app. Los datos de cada OT se toman de su primera fila; cada fila agrega un paso.
    Una OT con el mismo título, técnico y fecha de inicio que una ya registrada se omite"""
    resultado = resultado or ResultadoImportacion()

    tecnicos = {}  # nombre completo normalizado -> id del técnico, solo los del grupo
    for tecnico in repositorio_tecnicos.listar_por_supervisor(supervisor_usuario_id):
        usuario = repositorio_usuarios.obtener_por_id(tecnico.usuario_id)
        nombre = " ".join(p for p in (usuario.nombre, usuario.apellido_paterno, usuario.apellido_materno) if p)
        tecnicos[normalizar(nombre)] = tecnico.id
    ubicaciones = {
        niveles_de_ubicacion(" / ".join(n for n in (u.sector, u.subsector, u.sistema, u.subsistema) if n)): u.id
        for u in repositorio_ubicaciones.listar_ubicaciones()
    }

    for numero, filas_ot in _agrupar(filas).items():
        primera = filas_ot[0]
        dato = f"OT {numero}: {primera.titulo}" if numero else primera.titulo
        try:
            if not numero:
                raise OTInvalida(primera.fila, "Falta el número de OT")
            if not primera.titulo.strip():
                raise OTInvalida(primera.fila, "Falta el título")
            tipo = primera.tipo.strip().upper()
            if tipo not in TIPOS:
                raise OTInvalida(primera.fila, f"Tipo desconocido: {primera.tipo or 'vacío'} (use OE01, OE02, OE03 u OE04)")
            ubicacion_id = ubicaciones.get(niveles_de_ubicacion(primera.ubicacion))
            if ubicacion_id is None:
                raise OTInvalida(primera.fila, f"Ubicación técnica no registrada: {primera.ubicacion or 'vacía'}")
            tecnico_id = tecnicos.get(normalizar(primera.tecnico))
            if tecnico_id is None:
                raise OTInvalida(primera.fila, f"{primera.tecnico or 'El técnico'} no es un técnico de tu grupo")
            prioridad = numero_de(primera.prioridad)
            if prioridad is None or prioridad != int(prioridad):
                raise OTInvalida(primera.fila, f"La prioridad debe ser un número del 1 al 4, no {primera.prioridad or 'vacía'}")
            inicio, fin = fecha_de(primera.inicio), fecha_de(primera.fin)
            if inicio is None or fin is None:
                raise OTInvalida(primera.fila, "Las fechas deben tener el formato dd/mm/aaaa hh:mm")
            equipo = si_o_no(primera.equipo_en_funcionamiento)
            if equipo is None:
                raise OTInvalida(primera.fila, "Equipo en funcionamiento debe ser Sí o No")
            pasos = [_paso(f) for f in filas_ot]

            ya_existe = any(
                normalizar(ot.titulo) == normalizar(primera.titulo) and ot.fecha_inic_planif == inicio
                for ot in repositorio_ots.listar_por_tecnico(tecnico_id, inicio.date())
            )
            if ya_existe:
                resultado.omitidos.append(Aviso(primera.fila, dato, "Ya está registrada"))
                continue

            crear_ot(
                titulo=primera.titulo.strip(), tipo_de_orden=tipo, ubicacion_tecnica_id=ubicacion_id,
                tecnico_asignado_id=tecnico_id, prioridad=int(prioridad), estatus_equipo=equipo,
                fecha_inic_planif=inicio, fecha_fin_planif=fin, pasos=pasos,
                supervisor_usuario_id=supervisor_usuario_id, repositorio_ots=repositorio_ots,
                repositorio_ubicaciones=repositorio_ubicaciones, repositorio_tecnicos=repositorio_tecnicos,
                repositorio_supervisores=repositorio_supervisores,
            )
            resultado.ots_creadas += 1
        except OTInvalida as error:
            resultado.errores.append(Aviso(error.fila, dato, error.motivo))
        # las mismas reglas que al crear la OT en la app
        except SinPasoPM01:
            resultado.errores.append(Aviso(primera.fila, dato, "Se requiere al menos un paso PM01"))
        except (HorasInvalidas, DescripcionDePasoInvalida) as error:
            resultado.errores.append(Aviso(primera.fila, dato, str(error)))
        except PrioridadInvalida:
            resultado.errores.append(Aviso(primera.fila, dato, "La prioridad debe estar entre 1 y 4"))
        except FechasInvalidas:
            resultado.errores.append(Aviso(primera.fila, dato, "La fecha de fin no puede ser anterior a la de inicio"))
    return resultado
