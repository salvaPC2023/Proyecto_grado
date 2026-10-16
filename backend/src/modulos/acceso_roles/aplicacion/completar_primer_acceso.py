from uuid import UUID

from src.compartido.seguridad import hashear_password, verificar_password

from ..dominio.nombre_usuario import validar_nombre_usuario
from ..dominio.politica_password import validar_password
from ..dominio.puertos import RepositorioUsuarios
from .cambiar_password import PasswordDebil


class NombreUsuarioInvalido(Exception):
    def __init__(self, mensaje: str):
        super().__init__(mensaje)
        self.mensaje = mensaje


class NombreUsuarioEnUso(Exception):
    pass


class PrimerAccesoYaCompletado(Exception):
    pass


def completar_primer_acceso(
    usuario_id: UUID,
    nombre_usuario_nuevo: str,
    password_nueva: str,
    repositorio: RepositorioUsuarios,
) -> None:
    """El usuario recién creado elige su usuario (puede dejar el generado) y una contraseña propia"""
    usuario = repositorio.obtener_por_id(usuario_id)
    if usuario is None or not usuario.debe_cambiar_password:
        raise PrimerAccesoYaCompletado()

    nombre_usuario = nombre_usuario_nuevo.strip().lower()
    error = validar_nombre_usuario(nombre_usuario)
    if error:
        raise NombreUsuarioInvalido(error)
    otro = repositorio.obtener_por_nombre_usuario(nombre_usuario)
    if otro is not None and otro.id != usuario.id:
        raise NombreUsuarioEnUso()

    # la contraseña inicial es conocida por todos: no se puede conservar
    if verificar_password(password_nueva, usuario.password_hash):
        raise PasswordDebil(["La nueva contraseña debe ser distinta de la inicial."])
    errores = validar_password(password_nueva)
    if errores:
        raise PasswordDebil(errores)

    usuario.nombre_usuario = nombre_usuario
    usuario.password_hash = hashear_password(password_nueva)
    usuario.debe_cambiar_password = False
    repositorio.actualizar(usuario)
