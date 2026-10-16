import pytest
from fastapi.testclient import TestClient

from src.compartido.bd import get_db
from src.main import app
from src.modulos.acceso_roles.infraestructura import dependencias, router
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


@pytest.fixture
def cliente(monkeypatch):
    # el login y la validación del token usan el repositorio falso en lugar del de SQL
    recien_creado = crear_usuario(nombre_usuario="mqjgeubu", password="ESPODI2026")
    recien_creado.debe_cambiar_password = True
    usuarios = RepositorioUsuariosFalso([recien_creado], rol="tecnico")
    monkeypatch.setattr(router, "RepositorioUsuariosSQL", lambda db: usuarios)
    monkeypatch.setattr(dependencias, "RepositorioUsuariosSQL", lambda db: usuarios)
    app.dependency_overrides[get_db] = lambda: None
    yield TestClient(app)
    app.dependency_overrides.clear()


def _token(cliente, nombre_usuario="mqjgeubu", password="ESPODI2026"):
    respuesta = cliente.post("/api/v1/auth/login", json={"nombre_usuario": nombre_usuario, "password": password})
    return respuesta.json()


def test_el_login_responde_que_debe_cambiar_sus_credenciales(cliente):
    assert _token(cliente)["debe_cambiar_credenciales"] is True


def test_sin_cambiar_sus_datos_no_puede_usar_el_sistema(cliente):
    token = _token(cliente)["access_token"]

    respuesta = cliente.get("/api/v1/perfil", headers={"Authorization": f"Bearer {token}"})

    assert respuesta.status_code == 403


def test_al_cambiar_sus_datos_entra_con_los_nuevos(cliente):
    token = _token(cliente)["access_token"]

    respuesta = cliente.patch(
        "/api/v1/perfil/primer-acceso",
        json={"nombre_usuario": "cmamani", "password_nueva": "Segura#26"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert respuesta.status_code == 200
    nuevo = _token(cliente, "cmamani", "Segura#26")
    assert nuevo["debe_cambiar_credenciales"] is False
    # con el token nuevo ya pasa el control de acceso: el endpoint responde por la contraseña, no con 403
    otra_peticion = cliente.patch(
        "/api/v1/perfil/password",
        json={"password_actual": "equivocada", "password_nueva": "Otra#2026"},
        headers={"Authorization": f"Bearer {nuevo['access_token']}"},
    )
    assert otra_peticion.status_code == 401
    assert otra_peticion.json()["detail"] == "La contraseña actual es incorrecta"


def test_password_debil_responde_422_con_el_motivo(cliente):
    token = _token(cliente)["access_token"]

    respuesta = cliente.patch(
        "/api/v1/perfil/primer-acceso",
        json={"nombre_usuario": "cmamani", "password_nueva": "corta"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert respuesta.status_code == 422
    assert "8" in respuesta.json()["detail"]
