from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..dominio.modelos import UbicacionTecnica
from ..dominio.puertos import RepositorioUbicacionesTecnicas, UbicacionDuplicada, UbicacionEnUso
from .orm import UbicacionTecnicaORM


def ubicacion_a_dominio(orm: UbicacionTecnicaORM) -> UbicacionTecnica:
    return UbicacionTecnica(id=orm.id, sector=orm.sector, subsector=orm.subsector, sistema=orm.sistema, subsistema=orm.subsistema)


class RepositorioUbicacionesTecnicasSQL(RepositorioUbicacionesTecnicas):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def consulta_de_ubicaciones(self):
        return select(UbicacionTecnicaORM).order_by(UbicacionTecnicaORM.sector, UbicacionTecnicaORM.subsector, UbicacionTecnicaORM.sistema, UbicacionTecnicaORM.subsistema)

    def listar_ubicaciones(self) -> list[UbicacionTecnica]:
        filas = self._sesion.scalars(self.consulta_de_ubicaciones()).all()
        return [ubicacion_a_dominio(f) for f in filas]

    def obtener_por_id(self, id: UUID) -> UbicacionTecnica | None:
        orm = self._sesion.get(UbicacionTecnicaORM, id)
        return ubicacion_a_dominio(orm) if orm else None

    def guardar(self, orm: UbicacionTecnicaORM) -> UbicacionTecnica:
        try:
            self._sesion.commit()
        except IntegrityError:  # uq_ubicacion_niveles
            self._sesion.rollback()
            raise UbicacionDuplicada()
        self._sesion.refresh(orm)
        return ubicacion_a_dominio(orm)

    def crear(self, ubicacion: UbicacionTecnica) -> UbicacionTecnica:
        orm = UbicacionTecnicaORM(id=ubicacion.id, sector=ubicacion.sector, subsector=ubicacion.subsector, sistema=ubicacion.sistema, subsistema=ubicacion.subsistema)
        self._sesion.add(orm)
        return self.guardar(orm)

    def actualizar(self, ubicacion: UbicacionTecnica) -> UbicacionTecnica:
        orm = self._sesion.get(UbicacionTecnicaORM, ubicacion.id)
        orm.sector = ubicacion.sector
        orm.subsector = ubicacion.subsector
        orm.sistema = ubicacion.sistema
        orm.subsistema = ubicacion.subsistema
        return self.guardar(orm)

    def eliminar(self, id: UUID) -> None:
        self._sesion.delete(self._sesion.get(UbicacionTecnicaORM, id))
        try:
            self._sesion.commit()
        except IntegrityError:  # la usa una OT (llave foránea de ordenes_de_trabajo)
            self._sesion.rollback()
            raise UbicacionEnUso()
