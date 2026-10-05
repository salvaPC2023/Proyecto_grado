from uuid import uuid4

from src.modulos.acceso_roles.aplicacion.listar_tecnicos import listar_tecnicos
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioTecnicosFalso, crear_tecnico_de, crear_usuario


def test_el_supervisor_ve_solo_sus_tecnicos():
    supervisor, otro_supervisor = uuid4(), uuid4()
    mio = crear_tecnico_de(crear_usuario())
    ajeno = crear_tecnico_de(crear_usuario())
    repositorio = RepositorioTecnicosFalso([mio, ajeno], supervisor_de_tecnico={mio.id: supervisor, ajeno.id: otro_supervisor})

    assert listar_tecnicos(supervisor, repositorio) == [mio]
