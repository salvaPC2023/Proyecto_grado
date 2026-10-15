from uuid import uuid4

from src.compartido.seguridad import hashear_password

from ..dominio.modelos import Usuario
from ..dominio.puertos import RepositorioAdministradores, RepositorioUsuarios


def asegurar_administrador(
    nombre_usuario: str,
    password: str,
    repositorio_usuarios: RepositorioUsuarios,
    repositorio_administradores: RepositorioAdministradores,
) -> bool:
    """Crea el administrador inicial si el sistema no tiene ninguno; True si lo creó"""
    if repositorio_administradores.existe_alguno():
        return False
    if repositorio_usuarios.obtener_por_nombre_usuario(nombre_usuario) is not None:
        return False

    usuario = repositorio_usuarios.crear(Usuario(
        id=uuid4(),
        nombre="Administrador",
        apellido_paterno="ESPODI",
        nombre_usuario=nombre_usuario,
        password_hash=hashear_password(password),
        activo=True,
        # la empresa entra con la contraseña inicial y debe cambiarla
        debe_cambiar_password=True,
    ))
    repositorio_administradores.crear(usuario.id)
    return True
