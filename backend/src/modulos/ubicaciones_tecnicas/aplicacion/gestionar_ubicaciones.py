from uuid import UUID, uuid4

from ..dominio.modelos import UbicacionTecnica
from ..dominio.puertos import RepositorioUbicacionesTecnicas


class UbicacionNoEncontrada(Exception):
    pass


class NivelesIncompletos(Exception):
    pass


def _limpiar(texto: str | None) -> str | None:
    texto = (texto or "").strip()
    return texto or None


def _niveles(sector, subsector, sistema, subsistema) -> tuple:
    niveles = tuple(_limpiar(n) for n in (sector, subsector, sistema, subsistema))
    # no se salta ningún nivel: un vacío solo puede ir seguido de vacíos
    hay_hueco = any(niveles[i] is None and niveles[i + 1] is not None for i in range(3))
    if niveles[0] is None or hay_hueco:
        raise NivelesIncompletos()
    return niveles


def crear_ubicacion(sector, subsector, sistema, subsistema, repositorio: RepositorioUbicacionesTecnicas) -> UbicacionTecnica:
    sector, subsector, sistema, subsistema = _niveles(sector, subsector, sistema, subsistema)
    return repositorio.crear(UbicacionTecnica(id=uuid4(), sector=sector, subsector=subsector, sistema=sistema, subsistema=subsistema))


def editar_ubicacion(id: UUID, sector, subsector, sistema, subsistema, repositorio: RepositorioUbicacionesTecnicas) -> UbicacionTecnica:
    if repositorio.obtener_por_id(id) is None:
        raise UbicacionNoEncontrada()
    sector, subsector, sistema, subsistema = _niveles(sector, subsector, sistema, subsistema)
    return repositorio.actualizar(UbicacionTecnica(id=id, sector=sector, subsector=subsector, sistema=sistema, subsistema=subsistema))


def borrar_ubicacion(id: UUID, repositorio: RepositorioUbicacionesTecnicas) -> None:
    if repositorio.obtener_por_id(id) is None:
        raise UbicacionNoEncontrada()
    repositorio.eliminar(id)
