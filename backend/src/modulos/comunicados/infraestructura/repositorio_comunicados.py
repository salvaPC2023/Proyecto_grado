from datetime import datetime
from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from ..dominio.modelos import Comunicado
from ..dominio.puertos import RepositorioComunicados
from .orm import ComunicadoORM


def comunicado_a_dominio(orm: ComunicadoORM) -> Comunicado:
    return Comunicado(
        id=orm.id, grupo_id=orm.grupo_id, supervisor_id=orm.supervisor_id, titulo=orm.titulo, categoria=orm.categoria,
        fecha_envio=orm.fecha_envio, fecha_expiracion=orm.fecha_expiracion, texto=orm.texto, imagen=orm.imagen,
        tecnico_id=orm.tecnico_id,
    )


class RepositorioComunicadosSQL(RepositorioComunicados):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def crear(self, comunicado: Comunicado) -> Comunicado:
        orm = ComunicadoORM(
            id=comunicado.id, grupo_id=comunicado.grupo_id, supervisor_id=comunicado.supervisor_id,
            tecnico_id=comunicado.tecnico_id, titulo=comunicado.titulo, texto=comunicado.texto,
            categoria=comunicado.categoria, imagen=comunicado.imagen,
            fecha_envio=comunicado.fecha_envio, fecha_expiracion=comunicado.fecha_expiracion,
        )
        self._sesion.add(orm)
        self._sesion.commit()
        self._sesion.refresh(orm)
        return comunicado_a_dominio(orm)

    def obtener_por_id(self, id: UUID) -> Comunicado | None:
        orm = self._sesion.get(ComunicadoORM, id)
        return comunicado_a_dominio(orm) if orm else None

    def listar_vigentes_para_tecnico(self, grupo_id: UUID, tecnico_id: UUID, ahora: datetime) -> list[Comunicado]:
        consulta = (
            select(ComunicadoORM)
            .where(
                ComunicadoORM.grupo_id == grupo_id,
                ComunicadoORM.fecha_expiracion > ahora,
                or_(ComunicadoORM.tecnico_id.is_(None), ComunicadoORM.tecnico_id == tecnico_id),
            )
            .order_by(ComunicadoORM.fecha_envio.desc())
        )
        return [comunicado_a_dominio(c) for c in self._sesion.scalars(consulta).all()]

    def listar_vigentes_de_supervisor(self, supervisor_id: UUID, ahora: datetime) -> list[Comunicado]:
        consulta = (
            select(ComunicadoORM)
            .where(ComunicadoORM.supervisor_id == supervisor_id, ComunicadoORM.fecha_expiracion > ahora)
            .order_by(ComunicadoORM.fecha_envio.desc())
        )
        return [comunicado_a_dominio(c) for c in self._sesion.scalars(consulta).all()]

    def eliminar(self, id: UUID) -> None:
        orm = self._sesion.get(ComunicadoORM, id)
        if orm is not None:
            self._sesion.delete(orm)
            self._sesion.commit()
