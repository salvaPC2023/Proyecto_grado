import pytest

from src.compartido.seguridad import verificar_password
from src.modulos.acceso_roles.aplicacion.cambiar_password import ContrasenaActualIncorrecta, cambiar_password
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


def test_cambia_la_password():
    usuario = crear_usuario(password="clave123")
    usuario.debe_cambiar_password = True
    repositorio = RepositorioUsuariosFalso([usuario])

    cambiar_password(usuario.id, "clave123", "nueva456", repositorio)

    assert verificar_password("nueva456", usuario.password_hash)
    assert usuario.debe_cambiar_password is False  # ya no se le pide cambiarla


def test_password_actual_incorrecta_lanza_error():
    usuario = crear_usuario(password="clave123")
    repositorio = RepositorioUsuariosFalso([usuario])

    with pytest.raises(ContrasenaActualIncorrecta):
        cambiar_password(usuario.id, "mala", "nueva456", repositorio)
