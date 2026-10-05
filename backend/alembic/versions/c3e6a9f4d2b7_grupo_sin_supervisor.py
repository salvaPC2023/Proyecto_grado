"""grupo sin supervisor

Revision ID: c3e6a9f4d2b7
Revises: b2d5f8e3c1a6
Create Date: 2026-10-05 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op


revision: str = 'c3e6a9f4d2b7'
down_revision: Union[str, Sequence[str], None] = 'b2d5f8e3c1a6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # un grupo queda sin supervisor cuando su supervisor pasa a un grupo nuevo
    op.alter_column('grupo', 'supervisor_id', nullable=True)


def downgrade() -> None:
    op.alter_column('grupo', 'supervisor_id', nullable=False)
