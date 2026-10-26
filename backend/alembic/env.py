import sys
from logging.config import fileConfig
from pathlib import Path

from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.compartido.bd import Base
from src.compartido.configuracion import settings

# los modelos se registran en Base.metadata al importarlos; sin esto, "alembic check" y
# "alembic revision --autogenerate" no ven ninguna tabla
from src.modulos.acceso_roles.infraestructura import orm as _orm_acceso_roles  # noqa: F401
from src.modulos.ubicaciones_tecnicas.infraestructura import orm as _orm_ubicaciones  # noqa: F401
from src.modulos.ordenes_trabajo.infraestructura import orm as _orm_ordenes  # noqa: F401
from src.modulos.comunicados.infraestructura import orm as _orm_comunicados  # noqa: F401
from src.modulos.notificaciones.infraestructura import orm as _orm_notificaciones  # noqa: F401

config = context.config

# las pruebas de integración pasan su propia base (espodi_test) en config.attributes
config.set_main_option("sqlalchemy.url", config.attributes.get("url", settings.database_url))

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
