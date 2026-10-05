"""ot creada por supervisor

Revision ID: f2f3a7d44740
Revises: 99baec971725
Create Date: 2026-10-04 21:22:47.186589

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'f2f3a7d44740'
down_revision: Union[str, Sequence[str], None] = '99baec971725'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_constraint('ordenes_de_trabajo_creado_por_id_fkey', 'ordenes_de_trabajo', type_='foreignkey')
    op.execute("UPDATE ordenes_de_trabajo o SET creado_por_id = s.id FROM supervisores s WHERE s.usuario_id = o.creado_por_id")
    op.create_foreign_key('ordenes_de_trabajo_creado_por_id_fkey', 'ordenes_de_trabajo', 'supervisores', ['creado_por_id'], ['id'])


def downgrade() -> None:
    op.drop_constraint('ordenes_de_trabajo_creado_por_id_fkey', 'ordenes_de_trabajo', type_='foreignkey')
    op.execute("UPDATE ordenes_de_trabajo o SET creado_por_id = s.usuario_id FROM supervisores s WHERE s.id = o.creado_por_id")
    op.create_foreign_key('ordenes_de_trabajo_creado_por_id_fkey', 'ordenes_de_trabajo', 'usuarios', ['creado_por_id'], ['id'])
