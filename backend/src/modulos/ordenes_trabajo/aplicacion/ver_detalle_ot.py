from uuid import UUID

from src.modulos.acceso_roles.dominio.puertos import RepositorioTecnicos

from ..dominio.modelos import OrdenDeTrabajo
from ..dominio.puertos import RepositorioOrdenesTrabajo


class OTNoEncontrada(Exception):
    pass


class SinAccesoAOT(Exception):
    pass


def ver_detalle_ot(ot_id: UUID, usuario_id: UUID, rol: str, repositorio_ots: RepositorioOrdenesTrabajo, repositorio_tecnicos: RepositorioTecnicos) -> OrdenDeTrabajo:
    ot = repositorio_ots.obtener_por_id(ot_id)
    if ot is None:
        raise OTNoEncontrada()

    if rol == "tecnico":
        tecnico = repositorio_tecnicos.obtener_por_usuario_id(usuario_id)
        if tecnico is None or ot.tecnico_asignado_id != tecnico.id:
            raise SinAccesoAOT()
        return ot

    if not repositorio_tecnicos.pertenece_a_supervisor(ot.tecnico_asignado_id, usuario_id):
        raise SinAccesoAOT()
    return ot
