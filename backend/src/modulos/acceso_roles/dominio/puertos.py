from abc import ABC, abstractmethod
from typing import Literal
from uuid import UUID

from .modelos import Usuario

Rol = Literal["supervisor", "tecnico"]


class RepositorioUsuarios(ABC):
    @abstractmethod
    def obtener_por_nombre_usuario(self, nombre_usuario: str) -> Usuario | None:
        ...

    @abstractmethod
    def obtener_rol(self, usuario_id: UUID) -> Rol:
        ...

    @abstractmethod
    def obtener_por_id(self, id: UUID) -> Usuario | None:
        ...

    @abstractmethod
    def crear(self, usuario: Usuario) -> Usuario:
        ...

    @abstractmethod
    def actualizar(self, usuario: Usuario) -> Usuario:
        ...
