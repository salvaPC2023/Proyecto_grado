from uuid import UUID, uuid4

from ..dominio.modelos import Grupo
from ..dominio.puertos import RepositorioGrupos, RepositorioSupervisores
from .cambiar_estado_supervisor import SupervisorNoEncontrado


class GrupoNoEncontrado(Exception):
    pass


def listar_grupos(repositorio_grupos: RepositorioGrupos) -> list[Grupo]:
    return repositorio_grupos.listar()


def asignar_supervisor(
    grupo_id: UUID,
    supervisor_id: UUID,
    repositorio_grupos: RepositorioGrupos,
    repositorio_supervisores: RepositorioSupervisores,
) -> None:
    grupo = repositorio_grupos.obtener_por_id(grupo_id)
    if grupo is None:
        raise GrupoNoEncontrado()
    if repositorio_supervisores.obtener_por_id(supervisor_id) is None:
        raise SupervisorNoEncontrado()
    if grupo.supervisor_id == supervisor_id:
        return

    # el grupo que tenía el supervisor pasa al supervisor anterior del grupo (intercambio)
    asignaciones = {grupo.id: supervisor_id}
    grupo_anterior = next((g for g in repositorio_grupos.listar() if g.supervisor_id == supervisor_id), None)
    if grupo_anterior is not None:
        asignaciones[grupo_anterior.id] = grupo.supervisor_id
    repositorio_grupos.asignar_supervisores(asignaciones)


def crear_grupo(
    nombre_de_grupo: str,
    supervisor_id: UUID,
    repositorio_grupos: RepositorioGrupos,
    repositorio_supervisores: RepositorioSupervisores,
) -> Grupo:
    supervisor = repositorio_supervisores.obtener_por_id(supervisor_id)
    if supervisor is None:
        raise SupervisorNoEncontrado()

    # se crea sin supervisor y luego se le asigna; el grupo anterior del supervisor queda sin supervisor
    grupo = repositorio_grupos.crear(Grupo(
        id=uuid4(),
        nombre_de_grupo=nombre_de_grupo,
        supervisor_id=None,
        horario_entrada=supervisor.horario_entrada,
        horario_salida=supervisor.horario_salida,
    ))
    asignar_supervisor(grupo.id, supervisor_id, repositorio_grupos, repositorio_supervisores)
    grupo.supervisor_id = supervisor_id
    return grupo
