import pytest

from src.compartido.seguridad import verificar_password
from src.modulos.acceso_roles.aplicacion.cambiar_password import ContrasenaActualIncorrecta, cambiar_password, PasswordDebil
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


def test_cambia_la_password():
    usuario = crear_usuario(password="clave123")
    usuario.debe_cambiar_password = True
    repositorio = RepositorioUsuariosFalso([usuario])

    cambiar_password(usuario.id, "clave123", "Nueva#456", repositorio)

    assert verificar_password("Nueva#456", usuario.password_hash)
    assert usuario.debe_cambiar_password is False  # ya no se le pide cambiarla


def test_password_actual_incorrecta_lanza_error():
    usuario = crear_usuario(password="clave123")
    repositorio = RepositorioUsuariosFalso([usuario])

    with pytest.raises(ContrasenaActualIncorrecta):
        cambiar_password(usuario.id, "mala", "Nueva#456", repositorio)

def test_password_debil_lanza_error():
    usuario = crear_usuario(password="clave123")
    repositorio = RepositorioUsuariosFalso([usuario])

    with pytest.raises(PasswordDebil):
        cambiar_password(usuario.id, "clave123", "corta", repositorio)


def test_password_igual_a_la_actual_lanza_error():
    usuario = crear_usuario(password="Clave#123")
    repositorio = RepositorioUsuariosFalso([usuario])

    with pytest.raises(PasswordDebil):
        cambiar_password(usuario.id, "Clave#123", "Clave#123", repositorio)