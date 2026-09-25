from dataclasses import dataclass
from uuid import UUID


@dataclass
class Usuario:
    id: UUID
    nombre: str
    apellido_paterno: str
    nombre_usuario: str
    password_hash: str
    activo: bool
    debe_cambiar_password: bool
    apellido_materno: str | None = None