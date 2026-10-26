import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from src.compartido.bd import Base

from src.modulos.acceso_roles.infraestructura import orm as _orm_acceso_roles  # noqa: F401  (usuarios)


class DispositivoORM(Base):
    """Celular en el que un usuario tiene la sesión abierta, identificado por su token de Firebase"""
    __tablename__ = "dispositivos"

    token: Mapped[str] = mapped_column(String(512), primary_key=True)
    usuario_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("usuarios.id"), index=True)
    actualizado: Mapped[datetime] = mapped_column(DateTime)
