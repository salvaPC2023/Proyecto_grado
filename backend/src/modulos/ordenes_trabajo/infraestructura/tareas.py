import asyncio
import logging
from datetime import datetime

from src.compartido.bd import SessionLocal

from ..aplicacion.cerrar_vencidas import cerrar_ots_vencidas
from .repositorio_ordenes_trabajo import RepositorioOrdenesTrabajoSQL

registro = logging.getLogger("uvicorn.error")
INTERVALO_SEGUNDOS = 15 * 60


def cerrar_vencidas_ahora() -> None:
    with SessionLocal() as sesion:
        cerrados = cerrar_ots_vencidas(datetime.now(), RepositorioOrdenesTrabajoSQL(sesion))
    if cerrados:
        registro.info("Pasos cerrados automáticamente por vencimiento: %d", cerrados)


async def cerrar_vencidas_periodicamente() -> None:
    """Se revisa al arrancar (en Render el backend despierta después de dormir y puede haber OT vencidas
    mientras tanto) y luego cada 15 minutos mientras esté encendido"""
    while True:
        try:
            await asyncio.to_thread(cerrar_vencidas_ahora)
        except Exception:  # un fallo de la base no debe detener las revisiones siguientes
            registro.exception("Falló el cierre automático de OT vencidas")
        await asyncio.sleep(INTERVALO_SEGUNDOS)
