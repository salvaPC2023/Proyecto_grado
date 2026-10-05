import uuid
from datetime import datetime

from sqlalchemy import DateTime, String, func
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
    # la base pone la fecha al crear; al editar se actualiza sola
    fecha_modificacion: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
