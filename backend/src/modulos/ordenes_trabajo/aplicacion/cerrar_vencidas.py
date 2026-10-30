from datetime import datetime
from decimal import Decimal
from uuid import uuid4

from ..dominio.modelos import DESCRIPCION_CIERRE_AUTOMATICO, CierrePaso
from ..dominio.puertos import CierreDuplicado, RepositorioOrdenesTrabajo


def cerrar_ots_vencidas(ahora: datetime, repositorio_ots: RepositorioOrdenesTrabajo) -> int:
    """Un día después del fin planificado, cada PM01 sin cerrar se cierra como no ejecutado, con tiempo 0,
    y la OT queda cerrada. Así el supervisor y el Excel muestran qué no se hizo, en vez de OT abiertas
    para siempre. Devuelve cuántos pasos cerró"""
    cerrados = 0
    for ot in repositorio_ots.listar_vencidas(ahora):
        pendientes = [p for p in ot.pasos if p.clave_control == "PM01" and p.cierre is None]
        for i, paso in enumerate(pendientes):
            es_el_ultimo = i == len(pendientes) - 1
            cierre = CierrePaso(
                id=uuid4(), paso_ot_id=paso.id, fecha_hora_notificacion=ot.vencimiento,
                tiempo_real_trabajado=Decimal("0"), trabajo_finalizado=es_el_ultimo, sin_trabajo_realizado=True,
                resultado_trabajo="no_ejecutado", descripcion_trabajo_realizado=DESCRIPCION_CIERRE_AUTOMATICO,
            )
            try:
                repositorio_ots.registrar_cierre(
                    ot.id, cierre, estatus="cerrada" if es_el_ultimo else "en_progreso",
                    fecha_cierre=ot.vencimiento if es_el_ultimo else None,
                )
                cerrados += 1
            except CierreDuplicado:
                pass  # el técnico lo cerró justo ahora (un cierre sin señal hecho a tiempo)
    return cerrados
