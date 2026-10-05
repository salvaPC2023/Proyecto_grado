from uuid import UUID

from ..dominio.puertos import RepositorioSupervisores, RepositorioUsuarios


class SupervisorNoEncontrado(Exception):
    pass


def cambiar_estado_supervisor(
    supervisor_id: UUID,
    activo: bool,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_usuarios: RepositorioUsuarios,
) -> None:
    supervisor = repositorio_supervisores.obtener_por_id(supervisor_id)
    if supervisor is None:
        raise SupervisorNoEncontrado()

    usuario = repositorio_usuarios.obtener_por_id(supervisor.usuario_id)
    usuario.activo = activo
    repositorio_usuarios.actualizar(usuario)
