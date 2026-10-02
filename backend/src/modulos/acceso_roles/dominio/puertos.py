from abc import ABC, abstractmethod
from typing import Literal
from uuid import UUID

from .modelos import Supervisor, Tecnico, Usuario

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


class RepositorioTecnicos(ABC):
    @abstractmethod
    def obtener_por_id(self, id: UUID) -> Tecnico | None:
        ...

    @abstractmethod
    def crear(self, tecnico: Tecnico) -> Tecnico:
        ...

    @abstractmethod
    def listar_por_supervisor(self, supervisor_usuario_id: UUID) -> list[Tecnico]:
        ...

    @abstractmethod
    def pertenece_a_supervisor(self, tecnico_id: UUID, supervisor_usuario_id: UUID) -> bool:
        ...

    @abstractmethod
    def obtener_grupo_del_supervisor(self, supervisor_usuario_id: UUID) -> UUID | None:
        ...

    @abstractmethod
    def obtener_por_usuario_id(self, usuario_id: UUID) -> Tecnico | None:
        ...

    @abstractmethod
    def obtener_nombre_grupo(self, grupo_id: UUID) -> str | None:
        ...


class RepositorioSupervisores(ABC):
    @abstractmethod
    def obtener_por_usuario_id(self, usuario_id: UUID) -> Supervisor | None:
        ...
