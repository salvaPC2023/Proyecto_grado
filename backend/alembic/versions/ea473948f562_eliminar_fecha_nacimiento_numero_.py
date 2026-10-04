"""eliminar fecha_nacimiento, numero_celular y genero de usuarios

Revision ID: ea473948f562
Revises: 638255deaa20
Create Date: 2026-09-26 20:21:35.740203

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'ea473948f562'
down_revision: Union[str, Sequence[str], None] = '638255deaa20'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column('usuarios', 'fecha_nacimiento')
    op.drop_column('usuarios', 'numero_celular')
    op.drop_column('usuarios', 'genero')


def downgrade() -> None:
    op.add_column('usuarios', sa.Column('fecha_nacimiento', sa.Date(), nullable=True))
    op.add_column('usuarios', sa.Column('numero_celular', sa.String(20), nullable=True))
    op.add_column('usuarios', sa.Column('genero', sa.String(20), nullable=True))
