from uuid import uuid4

import pytest

from src.modulos.acceso_roles.aplicacion.editar_perfil import editar_perfil
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


def test_actualiza_nombre_y_apellidos():
    usuario = crear_usuario()
    repositorio = RepositorioUsuariosFalso([usuario])

    resultado = editar_perfil(usuario.id, "Juan Carlos", "Perez", repositorio, apellido_materno="Lopez")

    assert resultado.nombre == "Juan Carlos"
    assert resultado.apellido_materno == "Lopez"


def test_usuario_inexistente_lanza_error():
    repositorio = RepositorioUsuariosFalso()

    with pytest.raises(ValueError):
        editar_perfil(uuid4(), "Juan", "Perez", repositorio)
