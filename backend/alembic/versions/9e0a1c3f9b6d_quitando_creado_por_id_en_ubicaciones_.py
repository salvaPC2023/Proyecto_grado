"""quitando creado_por_id en ubicaciones tecnicas

Revision ID: 9e0a1c3f9b6d
Revises: 7c8864ef48d8
Create Date: 2026-10-02 19:16:28.610878

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9e0a1c3f9b6d'
down_revision: Union[str, Sequence[str], None] = '7c8864ef48d8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.drop_column('ubicaciones_tecnicas', 'creado_por_id')
    op.create_unique_constraint('uq_ubicacion_niveles', 'ubicaciones_tecnicas', ['sector', 'subsector', 'sistema', 'subsistema'], postgresql_nulls_not_distinct=True)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('uq_ubicacion_niveles', 'ubicaciones_tecnicas', type_='unique')

    op.add_column('ubicaciones_tecnicas', sa.Column('creado_por_id', sa.UUID(), sa.ForeignKey('usuarios.id'), nullable=True))
