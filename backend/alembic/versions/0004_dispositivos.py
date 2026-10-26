"""dispositivos para las notificaciones push

Token de Firebase de cada celular en el que un usuario tiene la sesión abierta (tarjeta 23).

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-26

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0004"
down_revision: Union[str, Sequence[str], None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "dispositivos",
        sa.Column("token", sa.String(512), primary_key=True),
        sa.Column("usuario_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("usuarios.id"), nullable=False),
        sa.Column("actualizado", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_dispositivos_usuario_id", "dispositivos", ["usuario_id"])


def downgrade() -> None:
    op.drop_index("ix_dispositivos_usuario_id", table_name="dispositivos")
    op.drop_table("dispositivos")
