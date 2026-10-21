from dataclasses import dataclass
from datetime import datetime
from typing import Literal
from uuid import UUID

Categoria = Literal["seguridad", "mantenimiento", "produccion", "general"]


@dataclass
class Comunicado:
    id: UUID
    grupo_id: UUID  # grupo al que va; si el grupo cambia de supervisor, sus técnicos lo siguen viendo
    supervisor_id: UUID  # quien lo escribió; solo él puede retirarlo
    titulo: str
    categoria: Categoria
    fecha_envio: datetime
    fecha_expiracion: datetime
    texto: str | None = None
    imagen: str | None = None  # nombre del archivo guardado; None si no tiene
    tecnico_id: UUID | None = None  # None = general para todo el grupo; si no, personal

    @property
    def es_personal(self) -> bool:
        return self.tecnico_id is not None

    def vigente(self, ahora: datetime) -> bool:
        return self.fecha_expiracion > ahora
