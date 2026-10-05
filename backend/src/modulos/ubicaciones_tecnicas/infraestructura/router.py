from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from src.compartido.bd import get_db
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, requerir_administrador, requerir_supervisor_o_administrador

from ..aplicacion.gestionar_ubicaciones import NivelesIncompletos, UbicacionNoEncontrada, borrar_ubicacion, crear_ubicacion, editar_ubicacion
from ..aplicacion.listar_ubicaciones_tecnicas import listar_ubicaciones_tecnicas
from ..dominio.modelos import UbicacionTecnica
from ..dominio.puertos import UbicacionDuplicada, UbicacionEnUso
from .repositorio_ubicaciones_tecnicas import RepositorioUbicacionesTecnicasSQL

router_ubicaciones = APIRouter(prefix="/ubicaciones-tecnicas", tags=["ubicaciones tecnicas"])


class UbicacionOut(BaseModel):
    id: UUID
    sector: str
    subsector: str | None
    sistema: str | None
    subsistema: str | None


class UbicacionIn(BaseModel):
    sector: str = Field(max_length=100)
    subsector: str | None = Field(default=None, max_length=100)
    sistema: str | None = Field(default=None, max_length=100)
    subsistema: str | None = Field(default=None, max_length=100)


def a_ubicacion_out(ubicacion: UbicacionTecnica) -> UbicacionOut:
    return UbicacionOut(id=ubicacion.id, sector=ubicacion.sector, subsector=ubicacion.subsector, sistema=ubicacion.sistema, subsistema=ubicacion.subsistema)


ERROR_NIVELES = "El sector es obligatorio y no se puede saltar un nivel"
ERROR_DUPLICADA = "Ya existe una ubicación técnica con esos niveles"


@router_ubicaciones.get("", response_model=list[UbicacionOut])
def listar_ubicaciones_tecnicas_endpoint(db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_supervisor_o_administrador)):
    repositorio_ubicaciones = RepositorioUbicacionesTecnicasSQL(db)
    ubicaciones = listar_ubicaciones_tecnicas(repositorio_ubicaciones)
    return [a_ubicacion_out(u) for u in ubicaciones]


@router_ubicaciones.post("", response_model=UbicacionOut, status_code=status.HTTP_201_CREATED)
def crear_ubicacion_endpoint(datos: UbicacionIn, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_administrador)):
    try:
        ubicacion = crear_ubicacion(datos.sector, datos.subsector, datos.sistema, datos.subsistema, RepositorioUbicacionesTecnicasSQL(db))
    except NivelesIncompletos:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=ERROR_NIVELES)
    except UbicacionDuplicada:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=ERROR_DUPLICADA)
    return a_ubicacion_out(ubicacion)


@router_ubicaciones.put("/{ubicacion_id}", response_model=UbicacionOut)
def editar_ubicacion_endpoint(ubicacion_id: UUID, datos: UbicacionIn, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_administrador)):
    try:
        ubicacion = editar_ubicacion(ubicacion_id, datos.sector, datos.subsector, datos.sistema, datos.subsistema, RepositorioUbicacionesTecnicasSQL(db))
    except UbicacionNoEncontrada:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ubicación técnica no encontrada")
    except NivelesIncompletos:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=ERROR_NIVELES)
    except UbicacionDuplicada:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=ERROR_DUPLICADA)
    return a_ubicacion_out(ubicacion)


@router_ubicaciones.delete("/{ubicacion_id}", status_code=status.HTTP_204_NO_CONTENT)
def borrar_ubicacion_endpoint(ubicacion_id: UUID, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_administrador)):
    try:
        borrar_ubicacion(ubicacion_id, RepositorioUbicacionesTecnicasSQL(db))
    except UbicacionNoEncontrada:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ubicación técnica no encontrada")
    except UbicacionEnUso:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="No se puede borrar: una orden de trabajo usa esta ubicación")
