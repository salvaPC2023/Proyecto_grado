"""quitar auth_user_id de usuarios, especializacion de tecnicos y activo de grupos

Revision ID: 7c8864ef48d8
Revises: ea473948f562
Create Date: 2026-10-02 14:38:45.546217

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7c8864ef48d8'
down_revision: Union[str, Sequence[str], None] = 'ea473948f562'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
