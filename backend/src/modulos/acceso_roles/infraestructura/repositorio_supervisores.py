from uuid import UUID
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..dominio.modelos import Grupo, Supervisor
from ..dominio.puertos import RepositorioSupervisores
from .orm import GrupoORM, SupervisorORM, UsuarioORM

def supervisor_a_dominio(orm: SupervisorORM) -> Supervisor:
    return Supervisor(
        id=orm.id,
        usuario_id=orm.usuario_id,
        horario_entrada=orm.horario_entrada,
        horario_salida=orm.horario_salida,
        area_designada=orm.area_designada,
    )

def grupo_a_dominio(orm: GrupoORM) -> Grupo:
    return Grupo(
        id=orm.id,
        nombre_de_grupo=orm.nombre_de_grupo,
        supervisor_id=orm.supervisor_id,
        horario_entrada=orm.horario_entrada,
        horario_salida=orm.horario_salida,
    )

class RepositorioSupervisoresSQL(RepositorioSupervisores):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def obtener_por_usuario_id(self, usuario_id: UUID) -> Supervisor | None:
        orm = self._sesion.scalars(
            select(SupervisorORM).where(SupervisorORM.usuario_id == usuario_id)
        ).first()
        return supervisor_a_dominio(orm) if orm else None

    def obtener_por_id(self, id: UUID) -> Supervisor | None:
        orm = self._sesion.get(SupervisorORM, id)
        return supervisor_a_dominio(orm) if orm else None

    def crear(self, supervisor: Supervisor, grupo: Grupo) -> Supervisor:
        orm = SupervisorORM(
            id=supervisor.id,
            usuario_id=supervisor.usuario_id,
            horario_entrada=supervisor.horario_entrada,
            horario_salida=supervisor.horario_salida,
            area_designada=supervisor.area_designada,
        )
        self._sesion.add(orm)
        self._sesion.flush()  # el grupo necesita que el supervisor ya exista
        self._sesion.add(GrupoORM(
            id=grupo.id,
            nombre_de_grupo=grupo.nombre_de_grupo,
            supervisor_id=grupo.supervisor_id,
            horario_entrada=grupo.horario_entrada,
            horario_salida=grupo.horario_salida,
        ))
        self._sesion.commit()
        self._sesion.refresh(orm)
        return supervisor_a_dominio(orm)

    def listar(self) -> list[Supervisor]:
        filas = self._sesion.scalars(
            select(SupervisorORM)
            .join(UsuarioORM, SupervisorORM.usuario_id == UsuarioORM.id)
            .order_by(UsuarioORM.apellido_paterno, UsuarioORM.nombre)
        ).all()
        return [supervisor_a_dominio(f) for f in filas]

    def obtener_grupo(self, supervisor_id: UUID) -> Grupo | None:
        orm = self._sesion.scalars(
            select(GrupoORM).where(GrupoORM.supervisor_id == supervisor_id)
        ).first()
        return grupo_a_dominio(orm) if orm else None
