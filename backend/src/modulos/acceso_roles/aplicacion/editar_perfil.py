from uuid import UUID

from ..dominio.modelos import Usuario
from ..dominio.puertos import RepositorioUsuarios


def editar_perfil(
    usuario_id: UUID,
    nombre: str,
    apellido_paterno: str,
    repositorio: RepositorioUsuarios,
    apellido_materno: str | None = None,
) -> Usuario:
    usuario = repositorio.obtener_por_id(usuario_id)
    if usuario is None:
        raise ValueError(f"Usuario {usuario_id} no encontrado")

    usuario.nombre = nombre
    usuario.apellido_paterno = apellido_paterno
    usuario.apellido_materno = apellido_materno
    return repositorio.actualizar(usuario)
