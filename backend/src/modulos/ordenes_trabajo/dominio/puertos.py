from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from .modelos import OrdenDeTrabajo


class RepositorioOrdenesTrabajo(ABC):
    @abstractmethod
    def crear(self, ot: OrdenDeTrabajo) -> OrdenDeTrabajo:
        ...

    @abstractmethod
    def obtener_por_id(self, id: UUID) -> OrdenDeTrabajo | None:
        ...

    @abstractmethod
    def listar_por_tecnico(self, tecnico_id: UUID, fecha: date | None = None) -> list[OrdenDeTrabajo]:
        ...

    @abstractmethod
    def listar_por_grupo(self, grupo_id: UUID, fecha: date | None = None) -> list[OrdenDeTrabajo]:
        ...
