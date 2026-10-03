from uuid import UUID

from ..dominio.modelos import UbicacionTecnica
from ..dominio.puertos import RepositorioUbicacionesTecnicas


def listar_ubicaciones_tecnicas(repositorio_ubicaciones: RepositorioUbicacionesTecnicas) -> list[UbicacionTecnica]:
    return repositorio_ubicaciones.listar_ubicaciones()
