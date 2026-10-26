from uuid import UUID

from ..dominio.modelos import Tecnico
from ..dominio.puertos import RepositorioTecnicos


def listar_tecnicos(
    supervisor_usuario_id: UUID, repositorio_tecnicos: RepositorioTecnicos
) -> list[Tecnico]:
    return repositorio_tecnicos.listar_por_supervisor(supervisor_usuario_id)


def listar_tecnicos_del_grupo(grupo_id: UUID, repositorio_tecnicos: RepositorioTecnicos) -> list[Tecnico]:
    """Para el administrador, que no tiene grupo propio"""
    return repositorio_tecnicos.listar_por_grupo(grupo_id)
