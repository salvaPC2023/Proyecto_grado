import asyncio
import logging
from datetime import datetime, timedelta

from src.compartido.bd import SessionLocal
from src.compartido.configuracion import settings
from src.modulos.acceso_roles.infraestructura.repositorio_grupos import RepositorioGruposSQL
from src.modulos.acceso_roles.infraestructura.repositorio_supervisores import RepositorioSupervisoresSQL
from src.modulos.acceso_roles.infraestructura.repositorio_tecnicos import RepositorioTecnicosSQL
from src.modulos.acceso_roles.infraestructura.repositorio_usuarios import RepositorioUsuariosSQL
from src.modulos.ordenes_trabajo.infraestructura.repositorio_ordenes_trabajo import RepositorioOrdenesTrabajoSQL

from ..aplicacion.avisos_fin_de_turno import enviar_avisos_de_fin_de_turno
from .repositorio_dispositivos import RepositorioDispositivosSQL
from .servicio_firebase import ServicioNotificacionesFirebase

registro = logging.getLogger("uvicorn.error")


def revisar(desde: datetime, hasta: datetime) -> None:
    with SessionLocal() as sesion:
        enviadas = enviar_avisos_de_fin_de_turno(
            desde, hasta, RepositorioGruposSQL(sesion), RepositorioTecnicosSQL(sesion), RepositorioUsuariosSQL(sesion),
            RepositorioSupervisoresSQL(sesion), RepositorioOrdenesTrabajoSQL(sesion), RepositorioDispositivosSQL(sesion),
            ServicioNotificacionesFirebase(),
        )
    if enviadas:
        registro.info("Avisos de fin de turno enviados: %d", len(enviadas))


async def revisar_turnos_periodicamente() -> None:
    """Corre mientras el backend está encendido. Cada revisión cubre el tiempo que pasó desde la anterior,
    así ningún aviso se pierde ni se repite aunque la revisión se atrase un poco"""
    intervalo = timedelta(minutes=settings.notificaciones_intervalo_minutos)
    anterior = datetime.now()
    while True:
        await asyncio.sleep(intervalo.total_seconds())
        ahora = datetime.now()
        try:
            await asyncio.to_thread(revisar, anterior, ahora)
        except Exception:  # un fallo (base caída, Firebase) no debe detener las revisiones siguientes
            registro.exception("Falló la revisión de avisos de fin de turno")
        anterior = ahora
