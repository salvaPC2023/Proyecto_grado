from datetime import date
from uuid import UUID

from src.modulos.acceso_roles.dominio.puertos import RepositorioTecnicos

from ..dominio.modelos import OrdenDeTrabajo
from ..dominio.puertos import RepositorioOrdenesTrabajo
from .listar_ots_supervisor import listar_ots_supervisor


class RangoInvalido(Exception):
    pass


def exportar_ots(
    supervisor_usuario_id: UUID,
    repositorio_ots: RepositorioOrdenesTrabajo,
    repositorio_tecnicos: RepositorioTecnicos,
    desde: date | None = None,
    hasta: date | None = None,
    ubicacion_tecnica_id: UUID | None = None,
) -> list[OrdenDeTrabajo]:
    if desde and hasta and desde > hasta:
        raise RangoInvalido()

    ots = listar_ots_supervisor(supervisor_usuario_id, repositorio_ots, repositorio_tecnicos)
    # igual que en la lista del grupo: entra la OT que estuvo vigente algún día del rango
    if desde:
        ots = [ot for ot in ots if ot.fecha_fin_planif.date() >= desde]
    if hasta:
        ots = [ot for ot in ots if ot.fecha_inic_planif.date() <= hasta]
    if ubicacion_tecnica_id:
        ots = [ot for ot in ots if ot.ubicacion_tecnica_id == ubicacion_tecnica_id]
    return ots
