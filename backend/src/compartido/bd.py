from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from src.compartido.configuracion import settings

# Neon suspende la base tras 5 minutos sin uso y corta las conexiones abiertas: antes de usar una se
# comprueba que siga viva, y ninguna se reutiliza pasados 4 minutos
engine = create_engine(settings.database_url, pool_pre_ping=True, pool_recycle=240)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
