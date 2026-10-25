from uuid import UUID
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from ..dominio.modelos import Grupo
from ..dominio.puertos import GrupoEnUso, RepositorioGrupos
from .orm import GrupoORM, SupervisorORM, TecnicoORM
from .repositorio_supervisores import grupo_a_dominio


class RepositorioGruposSQL(RepositorioGrupos):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def listar(self) -> list[Grupo]:
        filas = self._sesion.scalars(select(GrupoORM).order_by(GrupoORM.nombre_de_grupo)).all()
        return [grupo_a_dominio(f) for f in filas]

    def obtener_por_id(self, id: UUID) -> Grupo | None:
        orm = self._sesion.get(GrupoORM, id)
        return grupo_a_dominio(orm) if orm else None

    def crear(self, grupo: Grupo) -> Grupo:
        orm = GrupoORM(
            id=grupo.id,
            nombre_de_grupo=grupo.nombre_de_grupo,
            supervisor_id=grupo.supervisor_id,
            horario_entrada=grupo.horario_entrada,
            horario_salida=grupo.horario_salida,
        )
        self._sesion.add(orm)
        self._sesion.commit()
        self._sesion.refresh(orm)
        return grupo_a_dominio(orm)

    def asignar_supervisores(self, asignaciones: dict[UUID, UUID | None]) -> None:
        grupos = [self._sesion.get(GrupoORM, grupo_id) for grupo_id in asignaciones]
        # primero se vacían, porque un supervisor no puede estar en dos grupos a la vez (uq_grupo_supervisor)
        for grupo in grupos:
            grupo.supervisor_id = None
        self._sesion.flush()
        for grupo in grupos:
            grupo.supervisor_id = asignaciones[grupo.id]
            # el grupo pasa a trabajar en el turno de su nuevo supervisor
            if grupo.supervisor_id is not None:
                supervisor = self._sesion.get(SupervisorORM, grupo.supervisor_id)
                grupo.horario_entrada = supervisor.horario_entrada
                grupo.horario_salida = supervisor.horario_salida
        self._sesion.commit()

    def contar_tecnicos(self, grupo_id: UUID) -> int:
        return self._sesion.scalar(select(func.count()).select_from(TecnicoORM).where(TecnicoORM.grupo_id == grupo_id))

    def eliminar(self, id: UUID) -> None:
        self._sesion.delete(self._sesion.get(GrupoORM, id))
        try:
            self._sesion.commit()
        except IntegrityError:  # lo usa otra tabla, por ejemplo un comunicado (llave foránea a grupo)
            self._sesion.rollback()
            raise GrupoEnUso()
