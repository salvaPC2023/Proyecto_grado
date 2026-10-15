from uuid import UUID

from src.compartido.seguridad import hashear_password, verificar_password

from ..dominio.puertos import RepositorioUsuarios
from ..dominio.politica_password import validar_password


class ContrasenaActualIncorrecta(Exception):
    pass

class PasswordDebil(Exception):
    def __init__(self, errores: list[str]):
        super().__init__(" ".join(errores))
        self.errores = errores


def cambiar_password(
    usuario_id: UUID,
    password_actual: str,
    password_nueva: str,
    repositorio: RepositorioUsuarios,
) -> None:
    usuario = repositorio.obtener_por_id(usuario_id)
    if usuario is None or not verificar_password(
        password_actual, usuario.password_hash
    ):
        raise ContrasenaActualIncorrecta()

    if password_nueva == password_actual:
        raise PasswordDebil(["La nueva contraseña debe ser distinta de la actual."])
    errores = validar_password(password_nueva)
    if errores:
        raise PasswordDebil(errores)

    usuario.password_hash = hashear_password(password_nueva)
    usuario.debe_cambiar_password = False
    repositorio.actualizar(usuario)
