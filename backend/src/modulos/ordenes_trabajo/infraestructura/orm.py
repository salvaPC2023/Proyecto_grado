import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, ForeignKey, Numeric, SmallInteger, String, Text
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.compartido.bd import Base

from src.modulos.acceso_roles.infraestructura import orm as _orm_acceso_roles
from src.modulos.ubicaciones_tecnicas.infraestructura import orm as _orm_ubicaciones


class OrdenDeTrabajoORM(Base):
    __tablename__ = "ordenes_de_trabajo"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    titulo: Mapped[str] = mapped_column(String(150))
    tipo_de_orden: Mapped[str] = mapped_column(SQLEnum("OE01", "OE02", "OE03", "OE04", name="tipo_orden_enum", create_type=False))
    ubicacion_tecnica_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("ubicaciones_tecnicas.id"))
    creado_por_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("usuarios.id"))
    tecnico_asignado_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("tecnicos.id"))
    descripcion: Mapped[str] = mapped_column(Text)
    prioridad: Mapped[int] = mapped_column(SmallInteger)
    estatus: Mapped[str] = mapped_column(SQLEnum("asignada", "en_progreso", "cerrada", name="estatus_ot_enum", create_type=False))
    estatus_equipo: Mapped[bool] = mapped_column(Boolean)
    fecha_inic_planif: Mapped[datetime] = mapped_column(DateTime)
    fecha_fin_planif: Mapped[datetime] = mapped_column(DateTime)
    fecha_cierre: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    pasos: Mapped[list["PasoOTORM"]] = relationship(order_by="PasoOTORM.numero_paso", cascade="all, delete-orphan", lazy="selectin")


class PasoOTORM(Base):
    __tablename__ = "pasos_de_ots"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    ot_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("ordenes_de_trabajo.id"))
    numero_paso: Mapped[int] = mapped_column(SmallInteger)
    descripcion: Mapped[str] = mapped_column(Text)
    clave_control: Mapped[str] = mapped_column(SQLEnum("PM01", "PMNN", name="clave_control_enum", create_type=False))
    horas_planificadas: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
