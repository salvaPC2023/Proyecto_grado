"""comunicados

Tabla de comunicados del supervisor a su grupo (generales) o a un técnico de su grupo (personales).
La imagen se guarda como archivo en el servidor; aquí solo su nombre.

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-21

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0002"
down_revision: Union[str, Sequence[str], None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE TYPE categoria_comunicado_enum AS ENUM ('seguridad', 'mantenimiento', 'produccion', 'general')")
    op.create_table(
        "comunicados",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        # grupo al que va: si el grupo cambia de supervisor, sus técnicos lo siguen viendo
        sa.Column("grupo_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("grupo.id"), nullable=False),
        # quien lo escribió: solo él puede retirarlo
        sa.Column("supervisor_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("supervisores.id"), nullable=False),
        # vacío = general para todo el grupo; si no, personal
        sa.Column("tecnico_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("tecnicos.id"), nullable=True),
        sa.Column("titulo", sa.String(100), nullable=False),
        sa.Column("texto", sa.Text(), nullable=True),
        sa.Column(
            "categoria",
            postgresql.ENUM("seguridad", "mantenimiento", "produccion", "general", name="categoria_comunicado_enum", create_type=False),
            nullable=False,
        ),
        sa.Column("imagen", sa.String(60), nullable=True),
        sa.Column("fecha_envio", sa.DateTime(), nullable=False),
        sa.Column("fecha_expiracion", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_comunicados_grupo_expiracion", "comunicados", ["grupo_id", "fecha_expiracion"])


def downgrade() -> None:
    op.drop_index("ix_comunicados_grupo_expiracion", table_name="comunicados")
    op.drop_table("comunicados")
    op.execute("DROP TYPE categoria_comunicado_enum")
