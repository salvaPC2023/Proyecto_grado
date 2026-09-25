import uuid

from sqlalchemy import Boolean, Enum as SQLEnum, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from src.compartido.base_datos import Base


class UsuarioORM(Base):
    __tablename__ = "usuarios"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    nombre: Mapped[str] = mapped_column(String(100))
    apellido_paterno: Mapped[str] = mapped_column(String(100))
    apellido_materno: Mapped[str | None] = mapped_column(String(100), nullable=True)
    nombre_usuario: Mapped[str] = mapped_column(String(50), unique=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    activo: Mapped[bool] = mapped_column(Boolean, default=True)
    debe_cambiar_password: Mapped[bool] = mapped_column(Boolean, default=True)


class SupervisorORM(Base):
    __tablename__ = "supervisores"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    usuario_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("usuarios.id"), unique=True
    )


class TecnicoORM(Base):
    __tablename__ = "tecnicos"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    usuario_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("usuarios.id"), unique=True
    )
    grupo_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("grupo.id")
    )
    profesion: Mapped[str] = mapped_column(
        SQLEnum(
            "electrico",
            "mecanico",
            "electromecanico",
            name="profesion_enum",
            create_type=False,
        )
    )
