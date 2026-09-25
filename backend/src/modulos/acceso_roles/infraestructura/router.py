from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from src.compartido.base_datos import get_db

from ..aplicacion.iniciar_sesion import (
    CredencialesInvalidas,
    CuentaDeshabilitada,
    iniciar_sesion,
)
from .repositorio_usuarios import RepositorioUsuariosSQL

router = APIRouter(prefix="/auth", tags=["autenticacion"])


class CredencialesLogin(BaseModel):
    nombre_usuario: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str


@router.post("/login", response_model=TokenResponse)
def login(credenciales: CredencialesLogin, db: Session = Depends(get_db)):
    repositorio = RepositorioUsuariosSQL(db)
    try:
        resultado = iniciar_sesion(
            credenciales.nombre_usuario, credenciales.password, repositorio
        )
    except (CredencialesInvalidas, CuentaDeshabilitada):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
        )
    return TokenResponse(access_token=resultado.token, role=resultado.rol)
