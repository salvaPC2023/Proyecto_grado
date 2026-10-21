import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum as SQLEnum, ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from src.compartido.bd import Base

from src.modulos.acceso_roles.infraestructura import orm as _orm_acceso_roles  # noqa: F401  (grupo, supervisores, tecnicos)


class ComunicadoORM(Base):
    __tablename__ = "comunicados"
    # el tablón consulta los vigentes de un grupo
    __table_args__ = (Index("ix_comunicados_grupo_expiracion", "grupo_id", "fecha_expiracion"),)

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    grupo_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("grupo.id"))
    supervisor_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("supervisores.id"))
    tecnico_id: Mapped[uuid.UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("tecnicos.id"), nullable=True)
    titulo: Mapped[str] = mapped_column(String(100))
    texto: Mapped[str | None] = mapped_column(Text, nullable=True)
    categoria: Mapped[str] = mapped_column(
        SQLEnum("seguridad", "mantenimiento", "produccion", "general", name="categoria_comunicado_enum", create_type=False)
    )
    imagen: Mapped[str | None] = mapped_column(String(60), nullable=True)
    fecha_envio: Mapped[datetime] = mapped_column(DateTime)
    fecha_expiracion: Mapped[datetime] = mapped_column(DateTime)
