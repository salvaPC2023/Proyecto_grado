from uuid import uuid4

import pytest

from src.modulos.acceso_roles.aplicacion.cambiar_estado_cuenta import TecnicoNoEncontrado, cambiar_estado_cuenta
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioTecnicosFalso, RepositorioUsuariosFalso, crear_tecnico_de, crear_usuario

SUPERVISOR = uuid4()


def _repositorios():
    usuario = crear_usuario()
    tecnico = crear_tecnico_de(usuario)
    repositorio_usuarios = RepositorioUsuariosFalso([usuario])
    repositorio_tecnicos = RepositorioTecnicosFalso([tecnico], supervisor_de_tecnico={tecnico.id: SUPERVISOR})
    return usuario, tecnico, repositorio_usuarios, repositorio_tecnicos


def test_deshabilita_la_cuenta_del_tecnico():
    usuario, tecnico, repositorio_usuarios, repositorio_tecnicos = _repositorios()

    cambiar_estado_cuenta(tecnico.id, False, SUPERVISOR, repositorio_tecnicos, repositorio_usuarios)

    assert usuario.activo is False


def test_tecnico_de_otro_supervisor_lanza_error():
    _, tecnico, repositorio_usuarios, repositorio_tecnicos = _repositorios()

    with pytest.raises(TecnicoNoEncontrado):
        cambiar_estado_cuenta(tecnico.id, False, uuid4(), repositorio_tecnicos, repositorio_usuarios)


def test_tecnico_inexistente_lanza_error():
    _, _, repositorio_usuarios, repositorio_tecnicos = _repositorios()

    with pytest.raises(TecnicoNoEncontrado):
        cambiar_estado_cuenta(uuid4(), False, SUPERVISOR, repositorio_tecnicos, repositorio_usuarios)
