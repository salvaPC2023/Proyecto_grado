from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from src.compartido.bd import get_db
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, requerir_supervisor

from ..aplicacion.listar_ubicaciones_tecnicas import listar_ubicaciones_tecnicas
from ..dominio.modelos import UbicacionTecnica
from .repositorio_ubicaciones_tecnicas import RepositorioUbicacionesTecnicasSQL

# La ruta coincide con la que llama la app movil (repositorio_ordenes_trabajo_remoto.dart).
router_ubicaciones = APIRouter(prefix="/ubicaciones-tecnicas", tags=["ubicaciones tecnicas"])


class UbicacionOut(BaseModel):
    id: UUID
    sector: str
    subsector: str | None
    sistema: str | None
    subsistema: str | None


def a_ubicacion_out(ubicacion: UbicacionTecnica) -> UbicacionOut:
    return UbicacionOut(id=ubicacion.id, sector=ubicacion.sector, subsector=ubicacion.subsector, sistema=ubicacion.sistema, subsistema=ubicacion.subsistema)


@router_ubicaciones.get("", response_model=list[UbicacionOut])
def listar_ubicaciones_tecnicas_endpoint(db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_supervisor)):
    repositorio_ubicaciones = RepositorioUbicacionesTecnicasSQL(db)
    ubicaciones = listar_ubicaciones_tecnicas(repositorio_ubicaciones)
    return [a_ubicacion_out(u) for u in ubicaciones]
