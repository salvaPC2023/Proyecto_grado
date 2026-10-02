from uuid import UUID
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..dominio.modelos import Tecnico
from ..dominio.puertos import RepositorioTecnicos
from .orm import GrupoORM, SupervisorORM, TecnicoORM


def tecnico_a_dominio(orm: TecnicoORM) -> Tecnico:
    return Tecnico(
        id=orm.id,
        usuario_id=orm.usuario_id,
        grupo_id=orm.grupo_id,
        profesion=orm.profesion,
        creado_por_id=orm.creado_por_id,
    )


class RepositorioTecnicosSQL(RepositorioTecnicos):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def obtener_por_id(self, id: UUID) -> Tecnico | None:
        orm = self._sesion.get(TecnicoORM, id)
        return tecnico_a_dominio(orm) if orm else None

    def crear(self, tecnico: Tecnico) -> Tecnico:
        orm = TecnicoORM(
            id=tecnico.id,
            usuario_id=tecnico.usuario_id,
            grupo_id=tecnico.grupo_id,
            profesion=tecnico.profesion,
            creado_por_id=tecnico.creado_por_id,
        )
        self._sesion.add(orm)
        self._sesion.commit()
        self._sesion.refresh(orm)
        return tecnico_a_dominio(orm)

    def consulta_de_mi_grupo(self, supervisor_usuario_id: UUID):
        return (
            select(TecnicoORM)
            .join(GrupoORM, TecnicoORM.grupo_id == GrupoORM.id)
            .join(SupervisorORM, GrupoORM.supervisor_id == SupervisorORM.id)
            .where(SupervisorORM.usuario_id == supervisor_usuario_id)
        )

    def listar_por_supervisor(self, supervisor_usuario_id: UUID) -> list[Tecnico]:
        filas = self._sesion.scalars(self.consulta_de_mi_grupo(supervisor_usuario_id)).all()
        return [tecnico_a_dominio(f) for f in filas]

    def pertenece_a_supervisor(self, tecnico_id: UUID, supervisor_usuario_id: UUID) -> bool:
        consulta = self.consulta_de_mi_grupo(supervisor_usuario_id).where(
            TecnicoORM.id == tecnico_id
        )
        return self._sesion.scalars(consulta).first() is not None

    def obtener_grupo_del_supervisor(self, supervisor_usuario_id: UUID) -> UUID | None:
        return self._sesion.scalars(
            select(GrupoORM.id)
            .join(SupervisorORM, GrupoORM.supervisor_id == SupervisorORM.id)
            .where(SupervisorORM.usuario_id == supervisor_usuario_id)
        ).first()

    def obtener_por_usuario_id(self, usuario_id: UUID) -> Tecnico | None:
        orm = self._sesion.scalars(
            select(TecnicoORM).where(TecnicoORM.usuario_id == usuario_id)
        ).first()
        return tecnico_a_dominio(orm) if orm else None

    def obtener_nombre_grupo(self, grupo_id: UUID) -> str | None:
        return self._sesion.scalars(
            select(GrupoORM.nombre_de_grupo).where(GrupoORM.id == grupo_id)
        ).first()
