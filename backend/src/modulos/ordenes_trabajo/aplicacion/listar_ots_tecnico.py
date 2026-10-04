from datetime import date
from uuid import UUID

from src.modulos.acceso_roles.dominio.puertos import RepositorioTecnicos

from ..dominio.modelos import OrdenDeTrabajo
from ..dominio.puertos import RepositorioOrdenesTrabajo


def listar_ots_tecnico(tecnico_usuario_id: UUID, repositorio_ots: RepositorioOrdenesTrabajo, repositorio_tecnicos: RepositorioTecnicos, fecha: date | None = None) -> list[OrdenDeTrabajo]:
    tecnico = repositorio_tecnicos.obtener_por_usuario_id(tecnico_usuario_id)
    if tecnico is None:
        return []
    return repositorio_ots.listar_por_tecnico(tecnico.id, fecha)
