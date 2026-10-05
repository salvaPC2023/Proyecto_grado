import pytest

from src.modulos.acceso_roles.aplicacion.iniciar_sesion import CredencialesInvalidas, CuentaDeshabilitada, iniciar_sesion
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


def test_login_correcto_devuelve_token_y_rol():
    usuario = crear_usuario()
    repo = RepositorioUsuariosFalso([usuario], rol="tecnico")

    resultado = iniciar_sesion("tecnico01", "clave123", repo)

    assert resultado.token
    assert resultado.rol == "tecnico"


def test_usuario_inexistente_lanza_credenciales_invalidas():
    repo = RepositorioUsuariosFalso([])

    with pytest.raises(CredencialesInvalidas):
        iniciar_sesion("no_existe", "cualquiera", repo)


def test_password_incorrecta_lanza_credenciales_invalidas():
    usuario = crear_usuario(password="clave123")
    repo = RepositorioUsuariosFalso([usuario])

    with pytest.raises(CredencialesInvalidas):
        iniciar_sesion("tecnico01", "password_mala", repo)


def test_usuario_deshabilitado_lanza_cuenta_deshabilitada():
    usuario = crear_usuario(activo=False)
    repo = RepositorioUsuariosFalso([usuario])

    with pytest.raises(CuentaDeshabilitada):
        iniciar_sesion("tecnico01", "clave123", repo)
