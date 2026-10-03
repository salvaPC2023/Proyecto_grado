from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..dominio.modelos import UbicacionTecnica
from ..dominio.puertos import RepositorioUbicacionesTecnicas
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
