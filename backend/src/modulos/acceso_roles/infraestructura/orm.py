import uuid
from datetime import time
from sqlalchemy import Boolean, Enum as SQLEnum, ForeignKey, String, Time, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column
from src.compartido.bd import Base


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
    # el administrador no tiene datos ni relaciones propias: se distingue con este atributo.
    # supervisor y técnico no van aquí, porque ya los define su propia tabla
    rol: Mapped[str] = mapped_column(
        SQLEnum("comun", "admin", name="rol_usuario_enum", create_type=False),
        default="comun",
        server_default="comun",
    )

class SupervisorORM(Base):
    __tablename__ = "supervisores"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    usuario_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("usuarios.id"), unique=True
    )
    horario_entrada: Mapped[time] = mapped_column(Time)
    horario_salida: Mapped[time] = mapped_column(Time)
    area_designada: Mapped[str | None] = mapped_column(String(100), nullable=True)

class GrupoORM(Base):
    __tablename__ = "grupo"
    # un supervisor tiene un solo grupo
    __table_args__ = (UniqueConstraint("supervisor_id", name="uq_grupo_supervisor"),)

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    nombre_de_grupo: Mapped[str] = mapped_column(String(100))
    supervisor_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("supervisores.id"), nullable=True
    )
    horario_entrada: Mapped[time] = mapped_column(Time)
    horario_salida: Mapped[time] = mapped_column(Time)

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
    creado_por_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=True
    )
