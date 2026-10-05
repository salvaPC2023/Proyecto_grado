import pytest
from fastapi.testclient import TestClient

from src.compartido.bd import get_db
from src.main import app
from src.modulos.acceso_roles.infraestructura import router
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


@pytest.fixture
def cliente(monkeypatch):
    # el router usa el repositorio falso en lugar del de SQL
    usuarios = RepositorioUsuariosFalso([crear_usuario("frojas"), crear_usuario("inactivo", activo=False)], rol="supervisor")
    monkeypatch.setattr(router, "RepositorioUsuariosSQL", lambda db: usuarios)
    app.dependency_overrides[get_db] = lambda: None
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_login_correcto_devuelve_token_y_rol(cliente):
    respuesta = cliente.post("/api/v1/auth/login", json={"nombre_usuario": "frojas", "password": "clave123"})

    assert respuesta.status_code == 200
    assert respuesta.json()["role"] == "supervisor"
    assert respuesta.json()["access_token"]


def test_password_incorrecta_responde_401(cliente):
    respuesta = cliente.post("/api/v1/auth/login", json={"nombre_usuario": "frojas", "password": "otra"})

    assert respuesta.status_code == 401


def test_cuenta_deshabilitada_responde_401(cliente):
    respuesta = cliente.post("/api/v1/auth/login", json={"nombre_usuario": "inactivo", "password": "clave123"})

    assert respuesta.status_code == 401
    assert respuesta.json()["detail"] == "Usuario o contraseña incorrectos"  # mismo mensaje que credenciales incorrectas
