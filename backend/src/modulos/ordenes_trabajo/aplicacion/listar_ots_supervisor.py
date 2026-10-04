from datetime import date
from uuid import UUID

from src.modulos.acceso_roles.dominio.puertos import RepositorioTecnicos

from ..dominio.modelos import OrdenDeTrabajo
from ..dominio.puertos import RepositorioOrdenesTrabajo


def listar_ots_supervisor(supervisor_usuario_id: UUID, repositorio_ots: RepositorioOrdenesTrabajo, repositorio_tecnicos: RepositorioTecnicos, fecha: date | None = None) -> list[OrdenDeTrabajo]:
    grupo_id = repositorio_tecnicos.obtener_grupo_del_supervisor(supervisor_usuario_id)
    if grupo_id is None:
        return []
    return repositorio_ots.listar_por_grupo(grupo_id, fecha)
