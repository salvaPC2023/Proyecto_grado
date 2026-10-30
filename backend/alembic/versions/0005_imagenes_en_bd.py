"""imágenes de comunicados en la base de datos

Para desplegar en un servidor sin disco persistente (Render gratuito): con COMUNICADOS_ALMACEN=postgres
las imágenes se guardan en esta tabla en lugar de una carpeta del servidor.

Revision ID: 0005
Revises: 0004
Create Date: 2026-10-30

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0005"
down_revision: Union[str, Sequence[str], None] = "0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "imagenes_comunicados",
        sa.Column("nombre", sa.String(60), primary_key=True),
        sa.Column("contenido", sa.LargeBinary(), nullable=False),
        sa.Column("creada", sa.DateTime(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("imagenes_comunicados")
