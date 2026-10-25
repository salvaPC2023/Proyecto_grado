from datetime import time
from uuid import UUID

from ..dominio.modelos import Supervisor
from ..dominio.puertos import RepositorioGrupos, RepositorioSupervisores
from .cambiar_estado_supervisor import SupervisorNoEncontrado
from .crear_supervisor import HorarioInvalido
from .gestionar_grupos import asignar_supervisor


def editar_supervisor(
    supervisor_id: UUID,
    horario_entrada: time,
    horario_salida: time,
    area_designada: str | None,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_grupos: RepositorioGrupos,
    grupo_id: UUID | None = None,
) -> Supervisor:
    """Administrador: corrige el turno, el área y el grupo de un supervisor.
    El nombre y los apellidos no se editan aquí: los cambia la propia persona en Mi Perfil"""
    supervisor = repositorio_supervisores.obtener_por_id(supervisor_id)
    if supervisor is None:
        raise SupervisorNoEncontrado()
    if horario_entrada == horario_salida:
        raise HorarioInvalido()

    # primero el grupo: si el nuevo ya tenía supervisor, se intercambian;
    # luego el horario, para que el grupo nuevo tome el turno editado
    if grupo_id is not None:
        asignar_supervisor(grupo_id, supervisor_id, repositorio_grupos, repositorio_supervisores)

    supervisor.horario_entrada = horario_entrada
    supervisor.horario_salida = horario_salida
    supervisor.area_designada = (area_designada or "").strip() or None
    return repositorio_supervisores.actualizar(supervisor)
