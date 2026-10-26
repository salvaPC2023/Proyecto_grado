from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from src.compartido.bd import get_db
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual

from ..aplicacion.avisos_fin_de_turno import registrar_dispositivo
from .repositorio_dispositivos import RepositorioDispositivosSQL

router_notificaciones = APIRouter(prefix="/notificaciones", tags=["notificaciones"])


class DispositivoIn(BaseModel):
    token: str = Field(min_length=1, max_length=512)


@router_notificaciones.put("/dispositivo", status_code=status.HTTP_204_NO_CONTENT)
def registrar_dispositivo_endpoint(datos: DispositivoIn, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(obtener_usuario_actual)):
    """La app lo llama al iniciar sesión y cuando Firebase le cambia el token"""
    registrar_dispositivo(actual.id, datos.token, RepositorioDispositivosSQL(db))
