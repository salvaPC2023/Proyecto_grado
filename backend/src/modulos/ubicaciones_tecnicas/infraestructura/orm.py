import uuid

from sqlalchemy import String
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from src.compartido.bd import Base


class UbicacionTecnicaORM(Base):
    __tablename__ = "ubicaciones_tecnicas"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    sector: Mapped[str] = mapped_column(String(100))
    subsector: Mapped[str | None] = mapped_column(String(100), nullable=True)
    sistema: Mapped[str | None] = mapped_column(String(100), nullable=True)
    subsistema: Mapped[str | None] = mapped_column(String(100), nullable=True)
