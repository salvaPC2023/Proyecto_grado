from abc import ABC, abstractmethod
from uuid import UUID

from .modelos import OrdenDeTrabajo


class RepositorioOrdenesTrabajo(ABC):
    @abstractmethod
    def crear(self, ot: OrdenDeTrabajo) -> OrdenDeTrabajo:
        ...

    @abstractmethod
    def obtener_por_id(self, id: UUID) -> OrdenDeTrabajo | None:
        ...
