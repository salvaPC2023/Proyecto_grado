"""reglas de cierre de paso

Revision ID: a1c4e7d2b9f0
Revises: f2f3a7d44740
Create Date: 2026-10-05 15:00:00.000000

"""
from typing import Sequence, Union

from alembic import op


revision: str = 'a1c4e7d2b9f0'
down_revision: Union[str, Sequence[str], None] = 'f2f3a7d44740'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_unique_constraint('uq_cierre_paso', 'cierres_paso_ot', ['paso_ot_id'])
    op.create_check_constraint('ck_cierre_resultado', 'cierres_paso_ot', "resultado_trabajo IN ('ejecutado', 'no_ejecutado')")
    op.create_check_constraint('ck_cierre_tiempo', 'cierres_paso_ot', "(resultado_trabajo = 'ejecutado' AND tiempo_real_trabajado > 0) OR (resultado_trabajo = 'no_ejecutado' AND tiempo_real_trabajado = 0)")
    op.create_check_constraint('ck_cierre_sin_trabajo', 'cierres_paso_ot', "sin_trabajo_realizado = (resultado_trabajo = 'no_ejecutado')")


def downgrade() -> None:
    op.drop_constraint('ck_cierre_sin_trabajo', 'cierres_paso_ot', type_='check')
    op.drop_constraint('ck_cierre_tiempo', 'cierres_paso_ot', type_='check')
    op.drop_constraint('ck_cierre_resultado', 'cierres_paso_ot', type_='check')
    op.drop_constraint('uq_cierre_paso', 'cierres_paso_ot', type_='unique')
