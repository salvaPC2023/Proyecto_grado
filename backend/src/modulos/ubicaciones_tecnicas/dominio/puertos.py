from abc import ABC, abstractmethod
from uuid import UUID

from .modelos import UbicacionTecnica


class UbicacionDuplicada(Exception):
    """Ya existe una ubicación con los mismos cuatro niveles"""


class UbicacionEnUso(Exception):
    """Una OT usa la ubicación"""


class RepositorioUbicacionesTecnicas(ABC):
    @abstractmethod
    def listar_ubicaciones(self) -> list[UbicacionTecnica]:
        ...

    @abstractmethod
    def obtener_por_id(self, id: UUID) -> UbicacionTecnica | None:
        ...

    @abstractmethod
    def crear(self, ubicacion: UbicacionTecnica) -> UbicacionTecnica:
        ...

    @abstractmethod
    def actualizar(self, ubicacion: UbicacionTecnica) -> UbicacionTecnica:
        ...

    @abstractmethod
    def eliminar(self, id: UUID) -> None:
        ...
