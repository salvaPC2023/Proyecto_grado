from dataclasses import dataclass
from uuid import UUID


@dataclass
class UbicacionTecnica:
    id: UUID
    sector: str
    subsector: str | None = None
    sistema: str | None = None
    subsistema: str | None = None
