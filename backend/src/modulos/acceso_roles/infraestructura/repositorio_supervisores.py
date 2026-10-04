from uuid import UUID
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..dominio.modelos import Supervisor
from ..dominio.puertos import RepositorioSupervisores
from .orm import SupervisorORM

def supervisor_a_dominio(orm: SupervisorORM) -> Supervisor:
    return Supervisor(
        id=orm.id,
        usuario_id=orm.usuario_id,
        horario_entrada=orm.horario_entrada,
        horario_salida=orm.horario_salida,
        area_designada=orm.area_designada,
    )

class RepositorioSupervisoresSQL(RepositorioSupervisores):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def obtener_por_usuario_id(self, usuario_id: UUID) -> Supervisor | None:
        orm = self._sesion.scalars(
            select(SupervisorORM).where(SupervisorORM.usuario_id == usuario_id)
        ).first()
        return supervisor_a_dominio(orm) if orm else None
