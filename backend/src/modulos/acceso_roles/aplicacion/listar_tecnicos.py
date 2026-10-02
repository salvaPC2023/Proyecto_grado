from uuid import UUID

from ..dominio.modelos import Tecnico
from ..dominio.puertos import RepositorioTecnicos


def listar_tecnicos(
    supervisor_usuario_id: UUID, repositorio_tecnicos: RepositorioTecnicos
) -> list[Tecnico]:
    return repositorio_tecnicos.listar_por_supervisor(supervisor_usuario_id)
