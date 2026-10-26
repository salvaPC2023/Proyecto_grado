from datetime import time
from uuid import UUID

from src.modulos.acceso_roles.aplicacion.crear_supervisor import crear_supervisor
from src.modulos.acceso_roles.aplicacion.crear_tecnico import crear_tecnico
from src.modulos.acceso_roles.dominio.puertos import RepositorioSupervisores, RepositorioTecnicos, RepositorioUsuarios
from src.modulos.ordenes_trabajo.dominio.puertos import RepositorioOrdenesTrabajo
from src.modulos.ubicaciones_tecnicas.aplicacion.gestionar_ubicaciones import NivelesIncompletos, crear_ubicacion
from src.modulos.ubicaciones_tecnicas.dominio.puertos import RepositorioUbicacionesTecnicas, UbicacionDuplicada

from ..dominio.modelos import Aviso, FilaGrupo, FilaOT, FilaPersonal, FilaUbicacion, ResultadoImportacion, UsuarioCreado
from ..dominio.puertos import ConsultaPersonal, PlantillaInvalida
from ..dominio.reglas import horario_de_turno, normalizar, profesion_de, separar_nombre
from .importar_ots import importar_ots

# si el supervisor no está en la tabla de Grupos, su grupo trabaja en el turno 2
HORARIO_POR_DEFECTO = (time(7), time(15))
AYUDA_PERSONAL = "Personal lleva los encabezados: Nombre Completo, Grupo Planificador, Supervisor."
AYUDA_UBICACIONES = "Ubicaciones Técnicas lleva: Sector, Subsector, Sistema, Subsistema."
AYUDA_OTS = ("Órdenes de trabajo lleva: OT, Título, Tipo, Ubicación Técnica, Técnico, Prioridad, Inicio, Fin, "
             "Equipo en Funcionamiento, Clave, Descripción del Paso, Horas.")


class SupervisorSinGrupo(Exception):
    pass


class _Importacion:
    """Estado compartido de una importación: lo ya registrado y el resultado que se va armando"""

    def __init__(self, consulta: ConsultaPersonal, repositorio_usuarios: RepositorioUsuarios, repositorio_tecnicos: RepositorioTecnicos, creado_por_id: UUID):
        self.nombres = consulta.nombres_completos()
        self.repositorio_usuarios = repositorio_usuarios
        self.repositorio_tecnicos = repositorio_tecnicos
        self.creado_por_id = creado_por_id
        self.resultado = ResultadoImportacion()

    def omitir(self, fila: int, dato: str, motivo: str) -> None:
        self.resultado.omitidos.append(Aviso(fila, dato, motivo))

    def error(self, fila: int, dato: str, motivo: str) -> None:
        self.resultado.errores.append(Aviso(fila, dato, motivo))

    def registrar_tecnico(self, fila: FilaPersonal, grupo_id: UUID) -> None:
        partes = separar_nombre(fila.nombre_completo)
        profesion = profesion_de(fila.grupo_planificador)
        if partes is None:
            return self.error(fila.fila, fila.nombre_completo, "El nombre completo necesita al menos un nombre y un apellido")
        if profesion is None:
            return self.error(fila.fila, fila.nombre_completo, f"Grupo planificador desconocido: {fila.grupo_planificador}")
        if normalizar(fila.nombre_completo) in self.nombres:
            return self.omitir(fila.fila, fila.nombre_completo, "Ya está registrado")

        nombre, paterno, materno = partes
        tecnico = crear_tecnico(
            nombre=nombre, apellido_paterno=paterno, apellido_materno=materno,
            grupo_id=grupo_id, profesion=profesion, creado_por_id=self.creado_por_id,
            repositorio_usuarios=self.repositorio_usuarios, repositorio_tecnicos=self.repositorio_tecnicos,
        )
        self.nombres.add(normalizar(fila.nombre_completo))
        self.resultado.usuarios_creados.append(
            UsuarioCreado(fila.fila, fila.nombre_completo, self.nombre_usuario_de(tecnico.usuario_id), "tecnico")
        )

    def nombre_usuario_de(self, usuario_id: UUID) -> str:
        return self.repositorio_usuarios.obtener_por_id(usuario_id).nombre_usuario

    def registrar_ubicaciones(self, ubicaciones: list[FilaUbicacion], repositorio_ubicaciones: RepositorioUbicacionesTecnicas) -> None:
        for fila in ubicaciones:
            dato = " / ".join(n for n in (fila.sector, fila.subsector, fila.sistema, fila.subsistema) if n)
            try:
                crear_ubicacion(fila.sector, fila.subsector, fila.sistema, fila.subsistema, repositorio_ubicaciones)
                self.resultado.ubicaciones_creadas += 1
            except UbicacionDuplicada:
                self.omitir(fila.fila, dato, "Ya existe")
            except NivelesIncompletos:
                self.error(fila.fila, dato, "El sector es obligatorio y no se puede saltar un nivel")


def importar_carga_inicial(
    personal: list[FilaPersonal],
    ubicaciones: list[FilaUbicacion],
    administrador_usuario_id: UUID,
    consulta: ConsultaPersonal,
    repositorio_usuarios: RepositorioUsuarios,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_tecnicos: RepositorioTecnicos,
    repositorio_ubicaciones: RepositorioUbicacionesTecnicas,
    grupos: list[FilaGrupo] | None = None,
) -> ResultadoImportacion:
    """Administrador, carga inicial: ubicaciones técnicas, supervisores que falten (con su grupo) y técnicos de todos los grupos"""
    if not personal and not ubicaciones:
        raise PlantillaInvalida(f"No se encontró la tabla de Personal ni la de Ubicaciones Técnicas. {AYUDA_PERSONAL} {AYUDA_UBICACIONES}")

    importacion = _Importacion(consulta, repositorio_usuarios, repositorio_tecnicos, administrador_usuario_id)
    importacion.registrar_ubicaciones(ubicaciones, repositorio_ubicaciones)
    supervisores = consulta.supervisores_por_nombre()
    grupo_de = {normalizar(g.supervisor): g for g in grupos or []}

    def asegurar_supervisor(nombre_supervisor: str, fila: int) -> bool:
        """Crea al supervisor con su grupo si todavía no existe; False si no se pudo"""
        clave = normalizar(nombre_supervisor)
        if clave in supervisores:
            return True
        partes = separar_nombre(nombre_supervisor)
        if partes is None:
            importacion.error(fila, nombre_supervisor, "El nombre del supervisor necesita al menos un nombre y un apellido")
            return False
        nombre, paterno, materno = partes

        nombre_de_grupo, (entrada, salida) = f"Grupo {nombre} {paterno}", HORARIO_POR_DEFECTO
        fila_grupo = grupo_de.get(clave)
        if fila_grupo is not None:
            nombre_de_grupo = fila_grupo.grupo or nombre_de_grupo
            horario = horario_de_turno(fila_grupo.turno)
            if horario is None:
                importacion.error(fila_grupo.fila, fila_grupo.turno, "Turno desconocido (use Turno 1, 2 o 3); se asignó el turno 2")
            else:
                entrada, salida = horario

        supervisor = crear_supervisor(
            nombre=nombre, apellido_paterno=paterno, apellido_materno=materno,
            nombre_de_grupo=nombre_de_grupo, horario_entrada=entrada, horario_salida=salida,
            repositorio_usuarios=repositorio_usuarios, repositorio_supervisores=repositorio_supervisores,
        )
        supervisores[clave] = supervisor.id
        importacion.nombres.add(clave)
        importacion.resultado.usuarios_creados.append(
            UsuarioCreado(fila, nombre_supervisor, importacion.nombre_usuario_de(supervisor.usuario_id), "supervisor")
        )
        return True

    # primero los de la tabla de Grupos, para que también se creen los supervisores que aún no tienen técnicos
    for fila_grupo in grupos or []:
        if not normalizar(fila_grupo.supervisor):
            importacion.error(fila_grupo.fila, fila_grupo.grupo, "Falta el supervisor del grupo")
            continue
        asegurar_supervisor(fila_grupo.supervisor, fila_grupo.fila)

    for fila in personal:
        clave = normalizar(fila.supervisor)
        if not clave:
            importacion.error(fila.fila, fila.nombre_completo, "Falta el supervisor")
            continue
        if not asegurar_supervisor(fila.supervisor, fila.fila):
            continue

        grupo = repositorio_supervisores.obtener_grupo(supervisores[clave])
        if grupo is None:
            importacion.error(fila.fila, fila.nombre_completo, f"El supervisor {fila.supervisor} no tiene grupo")
            continue
        importacion.registrar_tecnico(fila, grupo.id)
    return importacion.resultado


def importar_para_mi_grupo(
    personal: list[FilaPersonal],
    ubicaciones: list[FilaUbicacion],
    supervisor_usuario_id: UUID,
    consulta: ConsultaPersonal,
    repositorio_usuarios: RepositorioUsuarios,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_tecnicos: RepositorioTecnicos,
    repositorio_ubicaciones: RepositorioUbicacionesTecnicas,
    ots: list[FilaOT] | None = None,
    repositorio_ots: RepositorioOrdenesTrabajo | None = None,
) -> ResultadoImportacion:
    """Supervisor: registra las ubicaciones técnicas, solo a los técnicos de su grupo y, si la plantilla
    trae la tabla de órdenes de trabajo, sus OT (después del personal, para poder asignarlas a técnicos nuevos)"""
    if not personal and not ubicaciones and not ots:
        raise PlantillaInvalida(
            f"No se encontró la tabla de Personal, la de Ubicaciones Técnicas ni la de Órdenes de trabajo. "
            f"{AYUDA_PERSONAL} {AYUDA_UBICACIONES} {AYUDA_OTS}"
        )

    grupo_id = repositorio_tecnicos.obtener_grupo_del_supervisor(supervisor_usuario_id)
    if grupo_id is None:
        raise SupervisorSinGrupo()
    importacion = _Importacion(consulta, repositorio_usuarios, repositorio_tecnicos, supervisor_usuario_id)

    importacion.registrar_ubicaciones(ubicaciones, repositorio_ubicaciones)

    supervisor = repositorio_supervisores.obtener_por_usuario_id(supervisor_usuario_id)
    mi_nombre = next((nombre for nombre, id in consulta.supervisores_por_nombre().items() if id == supervisor.id), None)
    for fila in personal:
        if normalizar(fila.supervisor) != mi_nombre:
            importacion.omitir(fila.fila, fila.nombre_completo, f"Es de otro grupo (supervisor {fila.supervisor or 'sin indicar'})")
            continue
        importacion.registrar_tecnico(fila, grupo_id)

    if ots:
        importar_ots(
            ots, supervisor_usuario_id, repositorio_ots, repositorio_ubicaciones, repositorio_tecnicos,
            repositorio_supervisores, repositorio_usuarios, resultado=importacion.resultado,
        )
    return importacion.resultado
