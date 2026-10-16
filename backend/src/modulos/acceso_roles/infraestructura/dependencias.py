from typing import NamedTuple
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from src.compartido.bd import get_db
from src.compartido.seguridad import decodificar_token

from ..dominio.modelos import Usuario
from .repositorio_usuarios import RepositorioUsuariosSQL

esquema_bearer = HTTPBearer()


class UsuarioAutenticado(NamedTuple):
    id: UUID
    rol: str


def _usuario_del_token(credenciales: HTTPAuthorizationCredentials, db: Session) -> tuple[Usuario, str]:
    try:
        payload = decodificar_token(credenciales.credentials)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalido o expirado",
        )

    usuario_id = UUID(payload["sub"])
    repositorio = RepositorioUsuariosSQL(db)
    usuario = repositorio.obtener_por_id(usuario_id)
    if usuario is None or not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalido o expirado",
        )
    return usuario, payload["role"]


def obtener_usuario_actual(
    credenciales: HTTPAuthorizationCredentials = Depends(esquema_bearer),
    db: Session = Depends(get_db),
) -> UsuarioAutenticado:
    usuario, rol = _usuario_del_token(credenciales, db)
    # el cambio en el primer acceso es obligatorio también para la API, no solo en la app
    if usuario.debe_cambiar_password:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes cambiar tu usuario y contraseña antes de usar el sistema",
        )
    return UsuarioAutenticado(id=usuario.id, rol=rol)


def obtener_usuario_en_primer_acceso(
    credenciales: HTTPAuthorizationCredentials = Depends(esquema_bearer),
    db: Session = Depends(get_db),
) -> UsuarioAutenticado:
    """Solo para el endpoint del primer acceso: acepta al usuario que todavía no cambió sus datos"""
    usuario, rol = _usuario_del_token(credenciales, db)
    return UsuarioAutenticado(id=usuario.id, rol=rol)


def requerir_administrador(
    actual: UsuarioAutenticado = Depends(obtener_usuario_actual),
) -> UsuarioAutenticado:
    if actual.rol != "administrador":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo un Administrador puede realizar esta accion",
        )
    return actual


def requerir_supervisor_o_administrador(
    actual: UsuarioAutenticado = Depends(obtener_usuario_actual),
) -> UsuarioAutenticado:
    if actual.rol not in ("supervisor", "administrador"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo un Supervisor o un Administrador puede realizar esta accion",
        )
    return actual


def requerir_supervisor(
    actual: UsuarioAutenticado = Depends(obtener_usuario_actual),
) -> UsuarioAutenticado:
    if actual.rol != "supervisor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo un Supervisor puede realizar esta accion",
        )
    return actual


def requerir_tecnico(
    actual: UsuarioAutenticado = Depends(obtener_usuario_actual),
) -> UsuarioAutenticado:
    if actual.rol != "tecnico":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo un Tecnico puede realizar esta accion",
        )
    return actual
