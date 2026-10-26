from uuid import UUID

from src.compartido.configuracion import settings
from src.compartido.seguridad import hashear_password

from ..dominio.modelos import Usuario
from ..dominio.puertos import RepositorioUsuarios


class CuentaNoEncontrada(Exception):
    pass


def restablecer_password(usuario_id: UUID, repositorio_usuarios: RepositorioUsuarios) -> Usuario:
    """El administrador devuelve la cuenta de un técnico o supervisor que olvidó su contraseña a la
    contraseña inicial; en el siguiente ingreso la persona debe elegir una nueva, como la primera vez"""
    usuario = repositorio_usuarios.obtener_por_id(usuario_id)
    # la cuenta del administrador no se restablece desde aquí
    if usuario is None or usuario.rol == "admin":
        raise CuentaNoEncontrada()

    usuario.password_hash = hashear_password(settings.default_technician_password)
    usuario.debe_cambiar_password = True
    return repositorio_usuarios.actualizar(usuario)
