"""esquema inicial

Crea la base completa desde cero. Reemplaza a las migraciones anteriores, que partían de un
script SQL que se perdió; quedan en el historial de git.

Las reglas sobre los valores de una fila (horas de un PM01, coherencia de un cierre, prioridad
de 1 a 4) las valida el backend. Aquí solo van las que comparan contra otras filas (unicidad),
porque esas solo la base puede garantizarlas cuando llegan dos peticiones a la vez.

Revision ID: 0001
Revises:
Create Date: 2026-10-19

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0001"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

ENUMS = {
    "rol_usuario_enum": ("comun", "admin"),
    "profesion_enum": ("electrico", "mecanico", "electromecanico"),
    "tipo_orden_enum": ("OE01", "OE02", "OE03", "OE04"),
    "estatus_ot_enum": ("asignada", "en_progreso", "cerrada"),
    "clave_control_enum": ("PM01", "PMNN"),
}


def _enum(nombre: str) -> postgresql.ENUM:
    # el tipo se crea aparte, en upgrade(), para que también funcione al generar el SQL
    return postgresql.ENUM(*ENUMS[nombre], name=nombre, create_type=False)


def upgrade() -> None:
    for nombre, valores in ENUMS.items():
        lista = ", ".join(f"'{v}'" for v in valores)
        op.execute(f"CREATE TYPE {nombre} AS ENUM ({lista})")

    op.create_table(
        "usuarios",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("nombre", sa.String(100), nullable=False),
        sa.Column("apellido_paterno", sa.String(100), nullable=False),
        sa.Column("apellido_materno", sa.String(100), nullable=True),
        sa.Column("nombre_usuario", sa.String(50), nullable=False, unique=True),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("activo", sa.Boolean(), nullable=False),
        sa.Column("debe_cambiar_password", sa.Boolean(), nullable=False),
        # comun o admin; supervisor y técnico se distinguen por su propia tabla
        sa.Column("rol", _enum("rol_usuario_enum"), nullable=False, server_default="comun"),
    )

    op.create_table(
        "supervisores",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("usuario_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("usuarios.id"), nullable=False, unique=True),
        sa.Column("horario_entrada", sa.Time(), nullable=False),
        sa.Column("horario_salida", sa.Time(), nullable=False),
        sa.Column("area_designada", sa.String(100), nullable=True),
    )

    op.create_table(
        "grupo",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("nombre_de_grupo", sa.String(100), nullable=False),
        # puede quedar sin supervisor; un supervisor tiene un solo grupo
        sa.Column("supervisor_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("supervisores.id"), nullable=True),
        sa.Column("horario_entrada", sa.Time(), nullable=False),
        sa.Column("horario_salida", sa.Time(), nullable=False),
        sa.UniqueConstraint("supervisor_id", name="uq_grupo_supervisor"),
    )

    op.create_table(
        "tecnicos",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("usuario_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("usuarios.id"), nullable=False, unique=True),
        sa.Column("grupo_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("grupo.id"), nullable=False),
        sa.Column("profesion", _enum("profesion_enum"), nullable=False),
        sa.Column("creado_por_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("usuarios.id"), nullable=True),
    )

    op.create_table(
        "ubicaciones_tecnicas",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("sector", sa.String(100), nullable=False),
        sa.Column("subsector", sa.String(100), nullable=True),
        sa.Column("sistema", sa.String(100), nullable=True),
        sa.Column("subsistema", sa.String(100), nullable=True),
        sa.Column("fecha_modificacion", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        # NULLS NOT DISTINCT: dos niveles vacíos cuentan como iguales
        sa.UniqueConstraint(
            "sector", "subsector", "sistema", "subsistema",
            name="uq_ubicacion_niveles", postgresql_nulls_not_distinct=True,
        ),
    )

    op.create_table(
        "ordenes_de_trabajo",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("titulo", sa.String(150), nullable=False),
        sa.Column("tipo_de_orden", _enum("tipo_orden_enum"), nullable=False),
        sa.Column("ubicacion_tecnica_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("ubicaciones_tecnicas.id"), nullable=False),
        sa.Column("creado_por_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("supervisores.id"), nullable=False),
        sa.Column("tecnico_asignado_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("tecnicos.id"), nullable=False),
        sa.Column("descripcion", sa.Text(), nullable=False),
        sa.Column("prioridad", sa.SmallInteger(), nullable=False),
        sa.Column("estatus", _enum("estatus_ot_enum"), nullable=False),
        sa.Column("estatus_equipo", sa.Boolean(), nullable=False),
        sa.Column("fecha_inic_planif", sa.DateTime(), nullable=False),
        sa.Column("fecha_fin_planif", sa.DateTime(), nullable=False),
        sa.Column("fecha_cierre", sa.DateTime(), nullable=True),
    )

    op.create_table(
        "pasos_de_ots",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("ot_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("ordenes_de_trabajo.id"), nullable=False),
        sa.Column("numero_paso", sa.SmallInteger(), nullable=False),
        sa.Column("descripcion", sa.Text(), nullable=False),
        sa.Column("clave_control", _enum("clave_control_enum"), nullable=False),
        sa.Column("horas_planificadas", sa.Numeric(5, 2), nullable=True),
        sa.UniqueConstraint("ot_id", "numero_paso", name="uq_paso_numero"),
    )

    op.create_table(
        "cierres_paso_ot",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("paso_ot_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("pasos_de_ots.id"), nullable=False),
        sa.Column("fecha_hora_notificacion", sa.DateTime(), nullable=False),
        sa.Column("tiempo_real_trabajado", sa.Numeric(5, 2), nullable=False),
        sa.Column("trabajo_finalizado", sa.Boolean(), nullable=False),
        sa.Column("sin_trabajo_realizado", sa.Boolean(), nullable=False),
        sa.Column("resultado_trabajo", sa.String(12), nullable=False),
        sa.Column("descripcion_trabajo_realizado", sa.Text(), nullable=False),
        # un solo cierre por paso: un reenvío desde la cola del celular se rechaza
        sa.UniqueConstraint("paso_ot_id", name="uq_cierre_paso"),
    )


def downgrade() -> None:
    for tabla in ("cierres_paso_ot", "pasos_de_ots", "ordenes_de_trabajo", "ubicaciones_tecnicas",
                  "tecnicos", "grupo", "supervisores", "usuarios"):
        op.drop_table(tabla)
    for nombre in reversed(ENUMS):
        op.execute(f"DROP TYPE {nombre}")
