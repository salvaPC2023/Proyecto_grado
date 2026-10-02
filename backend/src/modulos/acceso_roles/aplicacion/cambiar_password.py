from uuid import UUID

from src.compartido.seguridad import hashear_password, verificar_password

from ..dominio.puertos import RepositorioUsuarios


class ContrasenaActualIncorrecta(Exception):
    pass


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

    usuario.password_hash = hashear_password(password_nueva)
    usuario.debe_cambiar_password = False
    repositorio.actualizar(usuario)
