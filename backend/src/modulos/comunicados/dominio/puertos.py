from abc import ABC, abstractmethod
from datetime import datetime
from uuid import UUID

from .modelos import Comunicado


class RepositorioComunicados(ABC):
    @abstractmethod
    def crear(self, comunicado: Comunicado) -> Comunicado:
        ...

    @abstractmethod
    def obtener_por_id(self, id: UUID) -> Comunicado | None:
        ...

    @abstractmethod
    def listar_vigentes_para_tecnico(self, grupo_id: UUID, tecnico_id: UUID, ahora: datetime) -> list[Comunicado]:
        """Los generales del grupo y los personales dirigidos al técnico, del más reciente al más antiguo"""
        ...

    @abstractmethod
    def listar_vigentes_de_supervisor(self, supervisor_id: UUID, ahora: datetime) -> list[Comunicado]:
        """Los que escribió el supervisor, del más reciente al más antiguo"""
        ...

    @abstractmethod
    def eliminar(self, id: UUID) -> None:
        ...


class AlmacenImagenes(ABC):
    """Dónde se guardan los archivos de imagen; el comunicado solo guarda el nombre"""

    @abstractmethod
    def guardar(self, contenido: bytes, extension: str) -> str:
        """Guarda la imagen y devuelve el nombre con que se guardó"""
        ...

    @abstractmethod
    def leer(self, nombre: str) -> bytes | None:
        ...

    @abstractmethod
    def eliminar(self, nombre: str) -> None:
        ...
