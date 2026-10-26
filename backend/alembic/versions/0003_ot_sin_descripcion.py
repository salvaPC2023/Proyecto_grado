"""OT sin descripción y pasos numerados desde 1

Pruebas con usuarios del 23/10/2026: la descripción general de la OT se quita, porque el trabajo ya
se detalla en sus pasos. Los 3 pasos de seguridad dejan de llevar número y los pasos del supervisor
empiezan en 1, no en 4.

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-25

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0003"
down_revision: Union[str, Sequence[str], None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

PASOS_SEGURIDAD = ("Piense de manera inteligente", "Vea, diga, haga algo", "Se tiene habilidades adecuadas para la tarea")


def upgrade() -> None:
    op.drop_column("ordenes_de_trabajo", "descripcion")

    op.alter_column("pasos_de_ots", "numero_paso", existing_type=sa.SmallInteger(), nullable=True)
    # en las OTs ya creadas, los pasos 1 a 3 son los de seguridad y los del supervisor empiezan en 4
    op.execute("UPDATE pasos_de_ots SET numero_paso = NULL WHERE numero_paso <= 3")
    op.execute("UPDATE pasos_de_ots SET numero_paso = numero_paso - 3 WHERE numero_paso IS NOT NULL")


def downgrade() -> None:
    op.execute("UPDATE pasos_de_ots SET numero_paso = numero_paso + 3 WHERE numero_paso IS NOT NULL")
    for numero, texto in enumerate(PASOS_SEGURIDAD, start=1):
        op.execute(
            sa.text("UPDATE pasos_de_ots SET numero_paso = :numero WHERE numero_paso IS NULL AND descripcion = :texto")
            .bindparams(numero=numero, texto=texto)
        )
    op.alter_column("pasos_de_ots", "numero_paso", existing_type=sa.SmallInteger(), nullable=False)

    op.add_column("ordenes_de_trabajo", sa.Column("descripcion", sa.Text(), nullable=False, server_default=""))
    op.alter_column("ordenes_de_trabajo", "descripcion", server_default=None)
