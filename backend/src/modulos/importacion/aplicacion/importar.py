from datetime import time
from uuid import UUID

from src.modulos.acceso_roles.aplicacion.crear_supervisor import crear_supervisor
from src.modulos.acceso_roles.aplicacion.crear_tecnico import crear_tecnico
from src.modulos.acceso_roles.dominio.puertos import RepositorioSupervisores, RepositorioTecnicos, RepositorioUsuarios
from src.modulos.ubicaciones_tecnicas.aplicacion.gestionar_ubicaciones import NivelesIncompletos, crear_ubicacion
from src.modulos.ubicaciones_tecnicas.dominio.puertos import RepositorioUbicacionesTecnicas, UbicacionDuplicada

from ..dominio.modelos import Aviso, FilaPersonal, FilaUbicacion, ResultadoImportacion, UsuarioCreado
from ..dominio.puertos import ConsultaPersonal, PlantillaInvalida
from ..dominio.reglas import generar_nombre_usuario, normalizar, profesion_de, separar_nombre

# la plantilla no trae el horario del supervisor: se usa el turno 2 hasta que se defina
HORARIO_POR_DEFECTO = (time(7), time(15))
AYUDA_PERSONAL = "Personal lleva los encabezados: Nombre Completo, Grupo Planificador, Supervisor."
AYUDA_UBICACIONES = "Ubicaciones Técnicas lleva: Sector, Subsector, Sistema, Subsistema."


class SupervisorSinGrupo(Exception):
    pass


class _Importacion:
    """Estado compartido de una importación: lo ya registrado y el resultado que se va armando"""

    def __init__(self, consulta: ConsultaPersonal, repositorio_usuarios: RepositorioUsuarios, repositorio_tecnicos: RepositorioTecnicos, creado_por_id: UUID):
        self.nombres = consulta.nombres_completos()
        self.ocupados = consulta.nombres_de_usuario()
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
        nombre_usuario = generar_nombre_usuario(nombre, paterno, materno, self.ocupados)
        crear_tecnico(
            nombre=nombre, apellido_paterno=paterno, apellido_materno=materno, nombre_usuario=nombre_usuario,
            grupo_id=grupo_id, profesion=profesion, creado_por_id=self.creado_por_id,
            repositorio_usuarios=self.repositorio_usuarios, repositorio_tecnicos=self.repositorio_tecnicos,
        )
        self.nombres.add(normalizar(fila.nombre_completo))
        self.ocupados.add(nombre_usuario)
        self.resultado.usuarios_creados.append(UsuarioCreado(fila.fila, fila.nombre_completo, nombre_usuario, "tecnico"))

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
) -> ResultadoImportacion:
    """Administrador, carga inicial: ubicaciones técnicas, supervisores que falten (con su grupo) y técnicos de todos los grupos"""
    if not personal and not ubicaciones:
        raise PlantillaInvalida(f"No se encontró la tabla de Personal ni la de Ubicaciones Técnicas. {AYUDA_PERSONAL} {AYUDA_UBICACIONES}")

    importacion = _Importacion(consulta, repositorio_usuarios, repositorio_tecnicos, administrador_usuario_id)
    importacion.registrar_ubicaciones(ubicaciones, repositorio_ubicaciones)
    supervisores = consulta.supervisores_por_nombre()

    for fila in personal:
        clave = normalizar(fila.supervisor)
        if not clave:
            importacion.error(fila.fila, fila.nombre_completo, "Falta el supervisor")
            continue
        if clave not in supervisores:
            partes = separar_nombre(fila.supervisor)
            if partes is None:
                importacion.error(fila.fila, fila.supervisor, "El nombre del supervisor necesita al menos un nombre y un apellido")
                continue
            nombre, paterno, materno = partes
            nombre_usuario = generar_nombre_usuario(nombre, paterno, materno, importacion.ocupados)
            supervisor = crear_supervisor(
                nombre=nombre, apellido_paterno=paterno, apellido_materno=materno, nombre_usuario=nombre_usuario,
                nombre_de_grupo=f"Grupo {nombre} {paterno}", horario_entrada=HORARIO_POR_DEFECTO[0], horario_salida=HORARIO_POR_DEFECTO[1],
                repositorio_usuarios=repositorio_usuarios, repositorio_supervisores=repositorio_supervisores,
            )
            supervisores[clave] = supervisor.id
            importacion.nombres.add(clave)
            importacion.ocupados.add(nombre_usuario)
            importacion.resultado.usuarios_creados.append(UsuarioCreado(fila.fila, fila.supervisor, nombre_usuario, "supervisor"))

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
) -> ResultadoImportacion:
    """Supervisor: registra las ubicaciones técnicas y solo a los técnicos de su grupo"""
    if not personal and not ubicaciones:
        raise PlantillaInvalida(f"No se encontró la tabla de Personal ni la de Ubicaciones Técnicas. {AYUDA_PERSONAL} {AYUDA_UBICACIONES}")

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
    return importacion.resultado
