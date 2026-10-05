from abc import ABC, abstractmethod
from datetime import date, datetime
from uuid import UUID

from .modelos import CierrePaso, EstatusOT, OrdenDeTrabajo


class CierreDuplicado(Exception):
    """El paso ya tiene un cierre"""


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

    @abstractmethod
    def registrar_cierre(self, ot_id: UUID, cierre: CierrePaso, estatus: EstatusOT, fecha_cierre: datetime | None) -> OrdenDeTrabajo:
        """Guarda el cierre y el estado de la OT juntos"""
        ...
