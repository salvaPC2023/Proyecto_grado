from ..dominio.modelos import Supervisor
from ..dominio.puertos import RepositorioSupervisores


def listar_supervisores(repositorio_supervisores: RepositorioSupervisores) -> list[Supervisor]:
    return repositorio_supervisores.listar()
