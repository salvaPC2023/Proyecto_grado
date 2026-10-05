from dataclasses import dataclass
from datetime import time
from typing import Literal
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


Profesion = Literal["electrico", "mecanico", "electromecanico"]


@dataclass
class Tecnico:
    id: UUID
    usuario_id: UUID
    grupo_id: UUID
    profesion: Profesion
    creado_por_id: UUID | None = None


@dataclass
class Supervisor:
    id: UUID
    usuario_id: UUID
    horario_entrada: time
    horario_salida: time
    area_designada: str | None = None


@dataclass
class Grupo:
    id: UUID
    nombre_de_grupo: str
    supervisor_id: UUID | None
    horario_entrada: time
    horario_salida: time
