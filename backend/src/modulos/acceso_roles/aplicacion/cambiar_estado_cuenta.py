from uuid import UUID

from ..dominio.puertos import RepositorioTecnicos, RepositorioUsuarios


class TecnicoNoEncontrado(Exception):
    pass

def cambiar_estado_cuenta(
    tecnico_id: UUID,
    activo: bool,
    supervisor_usuario_id: UUID,
    repositorio_tecnicos: RepositorioTecnicos,
    repositorio_usuarios: RepositorioUsuarios,
) -> None:
    tecnico = repositorio_tecnicos.obtener_por_id(tecnico_id)
    if tecnico is None or not repositorio_tecnicos.pertenece_a_supervisor(
        tecnico_id, supervisor_usuario_id
    ):
        raise TecnicoNoEncontrado()

    usuario = repositorio_usuarios.obtener_por_id(tecnico.usuario_id)
    usuario.activo = activo
    repositorio_usuarios.actualizar(usuario)
