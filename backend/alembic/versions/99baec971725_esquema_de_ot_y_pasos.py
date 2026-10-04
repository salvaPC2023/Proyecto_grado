"""esquema de ot y pasos

Revision ID: 99baec971725
Revises: 9e0a1c3f9b6d
Create Date: 2026-10-03 23:41:58.065156

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '99baec971725'
down_revision: Union[str, Sequence[str], None] = '9e0a1c3f9b6d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # NOT NULL sin valor por defecto: solo funciona porque la tabla esta vacia.
    op.add_column('ordenes_de_trabajo', sa.Column('titulo', sa.String(150), nullable=False))
    op.alter_column('ordenes_de_trabajo', 'estatus_instalacion', new_column_name='estatus_equipo')
    op.drop_column('pasos_de_ots', 'estatus')
    op.add_column('pasos_de_ots', sa.Column('numero_paso', sa.SmallInteger(), nullable=False))
    op.create_unique_constraint('uq_paso_numero', 'pasos_de_ots', ['ot_id', 'numero_paso'])
    op.create_check_constraint('ck_paso_pm01_con_horas', 'pasos_de_ots', "clave_control <> 'PM01' OR (horas_planificadas IS NOT NULL AND horas_planificadas > 0)")
    op.create_check_constraint('ck_paso_pmnn_sin_horas', 'pasos_de_ots', "clave_control <> 'PMNN' OR horas_planificadas IS NULL")


def downgrade() -> None:
    """Downgrade schema."""
    # Lo contrario del upgrade, de abajo hacia arriba.
    op.drop_constraint('ck_paso_pmnn_sin_horas', 'pasos_de_ots', type_='check')
    op.drop_constraint('ck_paso_pm01_con_horas', 'pasos_de_ots', type_='check')
    op.drop_constraint('uq_paso_numero', 'pasos_de_ots', type_='unique')
    op.drop_column('pasos_de_ots', 'numero_paso')
    op.add_column('pasos_de_ots', sa.Column('estatus', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.alter_column('ordenes_de_trabajo', 'estatus_equipo', new_column_name='estatus_instalacion')
    op.drop_column('ordenes_de_trabajo', 'titulo')

