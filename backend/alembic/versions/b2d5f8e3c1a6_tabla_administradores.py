"""tabla administradores

Revision ID: b2d5f8e3c1a6
Revises: a1c4e7d2b9f0
Create Date: 2026-10-05 15:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


revision: str = 'b2d5f8e3c1a6'
down_revision: Union[str, Sequence[str], None] = 'a1c4e7d2b9f0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # el rol se deduce de la tabla donde está el usuario
    op.create_table(
        'administradores',
        sa.Column('id', UUID(as_uuid=True), primary_key=True),
        sa.Column('usuario_id', UUID(as_uuid=True), sa.ForeignKey('usuarios.id'), nullable=False, unique=True),
    )


def downgrade() -> None:
    op.drop_table('administradores')
