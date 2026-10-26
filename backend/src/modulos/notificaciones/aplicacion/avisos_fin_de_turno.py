from datetime import date, datetime, timedelta
from uuid import UUID

from src.modulos.acceso_roles.dominio.modelos import Grupo
from src.modulos.acceso_roles.dominio.puertos import RepositorioGrupos, RepositorioSupervisores, RepositorioTecnicos, RepositorioUsuarios
from src.modulos.ordenes_trabajo.dominio.puertos import RepositorioOrdenesTrabajo

from ..dominio.modelos import Notificacion
from ..dominio.puertos import RepositorioDispositivos, ServicioNotificaciones

# Tarjeta 23: una hora antes del fin del turno, a quien le queden pasos PM01 sin cerrar
ANTICIPACION = timedelta(hours=1)
TITULO = "Pasos sin cerrar"


def _plural(cantidad: int) -> str:
    return f"{cantidad} paso{'' if cantidad == 1 else 's'}"


def turnos_por_avisar(grupos: list[Grupo], desde: datetime, hasta: datetime) -> list[tuple[Grupo, date]]:
    """Grupos cuyo aviso (una hora antes de su salida) cae en (desde, hasta], con el día en que termina el turno.
    El aviso del turno de 23:00 a 07:00 cae a las 06:00 del día en que termina; el de un turno que sale a las
    00:30, a las 23:30 del día anterior. Por eso se revisan también los días siguientes"""
    turnos = []
    for grupo in grupos:
        dia = desde.date()
        while dia <= hasta.date() + timedelta(days=1):
            aviso = datetime.combine(dia, grupo.horario_salida) - ANTICIPACION
            if desde < aviso <= hasta:
                turnos.append((grupo, dia))
            dia += timedelta(days=1)
    return turnos


def avisos_del_turno(
    grupo: Grupo,
    dia: date,
    repositorio_tecnicos: RepositorioTecnicos,
    repositorio_usuarios: RepositorioUsuarios,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_ots: RepositorioOrdenesTrabajo,
) -> list[Notificacion]:
    """Un aviso para cada técnico con pasos PM01 sin cerrar en sus OT del día y un resumen para el supervisor.
    Si no queda nada pendiente, no hay avisos"""
    avisos, pendientes_por_tecnico = [], []
    for tecnico in repositorio_tecnicos.listar_por_grupo(grupo.id):
        usuario = repositorio_usuarios.obtener_por_id(tecnico.usuario_id)
        if usuario is None or not usuario.activo:
            continue
        pendientes = sum(
            1
            for ot in repositorio_ots.listar_por_tecnico(tecnico.id, dia) if ot.estatus != "cerrada"
            for paso in ot.pasos if paso.clave_control == "PM01" and paso.cierre is None
        )
        if pendientes:
            avisos.append(Notificacion(usuario.id, TITULO, f"Tienes {_plural(pendientes)} sin cerrar. Regístralos antes de terminar tu turno."))
            pendientes_por_tecnico.append((f"{usuario.nombre} {usuario.apellido_paterno}", pendientes))

    supervisor = repositorio_supervisores.obtener_por_id(grupo.supervisor_id) if grupo.supervisor_id else None
    if supervisor is not None and pendientes_por_tecnico:
        detalle = ", ".join(f"{nombre} ({_plural(n)})" for nombre, n in pendientes_por_tecnico)
        cantidad = len(pendientes_por_tecnico)
        avisos.append(Notificacion(
            supervisor.usuario_id, TITULO,
            f"{cantidad} técnico{'' if cantidad == 1 else 's'} de {grupo.nombre_de_grupo} con pasos sin cerrar: {detalle}",
        ))
    return avisos


def enviar_avisos_de_fin_de_turno(
    desde: datetime,
    hasta: datetime,
    repositorio_grupos: RepositorioGrupos,
    repositorio_tecnicos: RepositorioTecnicos,
    repositorio_usuarios: RepositorioUsuarios,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_ots: RepositorioOrdenesTrabajo,
    repositorio_dispositivos: RepositorioDispositivos,
    servicio: ServicioNotificaciones,
) -> list[Notificacion]:
    """Lo llama el planificador cada pocos minutos con el intervalo que pasó desde la vez anterior"""
    enviadas = []
    for grupo, dia in turnos_por_avisar(repositorio_grupos.listar(), desde, hasta):
        for aviso in avisos_del_turno(grupo, dia, repositorio_tecnicos, repositorio_usuarios, repositorio_supervisores, repositorio_ots):
            tokens = repositorio_dispositivos.tokens_de(aviso.usuario_id)
            if not tokens:
                continue  # nunca abrió la app en un celular, o cerró sesión
            invalidos = servicio.enviar(tokens, aviso.titulo, aviso.cuerpo)
            if invalidos:
                repositorio_dispositivos.eliminar(invalidos)
            enviadas.append(aviso)
    return enviadas


def registrar_dispositivo(usuario_id: UUID, token: str, repositorio: RepositorioDispositivos) -> None:
    repositorio.registrar(usuario_id, token.strip())
