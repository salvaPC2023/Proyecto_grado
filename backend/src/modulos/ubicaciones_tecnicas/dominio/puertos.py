from abc import ABC, abstractmethod
from uuid import UUID

from .modelos import UbicacionTecnica

class RepositorioUbicacionesTecnicas(ABC):
    @abstractmethod
    def listar_ubicaciones(self) -> list[UbicacionTecnica]:
        ...

    @abstractmethod
    def obtener_por_id(self, id: UUID) -> UbicacionTecnica | None:
        ...