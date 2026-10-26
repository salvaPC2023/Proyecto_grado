from dataclasses import dataclass
from uuid import UUID


@dataclass
class Notificacion:
    usuario_id: UUID
    titulo: str
    cuerpo: str
