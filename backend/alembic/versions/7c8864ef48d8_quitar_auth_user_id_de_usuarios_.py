"""quitar auth_user_id de usuarios, especializacion de tecnicos y activo de grupos; un supervisor por grupo

Revision ID: 7c8864ef48d8
Revises: ea473948f562
Create Date: 2026-10-02 14:38:45.546217

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '7c8864ef48d8'
down_revision: Union[str, Sequence[str], None] = 'ea473948f562'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column('usuarios', 'auth_user_id')
    op.drop_column('tecnicos', 'especializacion')
    op.drop_column('grupo', 'activo')

    op.create_unique_constraint('uq_grupo_supervisor', 'grupo', ['supervisor_id'])


def downgrade() -> None:
    op.drop_constraint('uq_grupo_supervisor', 'grupo', type_='unique')

    op.add_column('grupo', sa.Column('activo', sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column('tecnicos', sa.Column('especializacion', sa.String(100), nullable=True))
    op.add_column('usuarios', sa.Column('auth_user_id', sa.String(100), nullable=True, unique=True))
