from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from src.main import app
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual


@pytest.fixture
def cliente():
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_token_invalido_responde_401(cliente):
    respuesta = cliente.get("/api/v1/perfil", headers={"Authorization": "Bearer token-falso"})

    assert respuesta.status_code == 401
    assert respuesta.json()["detail"] == "Token invalido o expirado"


def test_supervisor_no_puede_ver_mis_ots(cliente):
    # simula un supervisor logueado sin pasar por la base de datos
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol="supervisor")

    respuesta = cliente.get("/api/v1/ordenes-trabajo/mis-ots")

    assert respuesta.status_code == 403
    assert respuesta.json()["detail"] == "Solo un Tecnico puede realizar esta accion"


def test_supervisor_no_puede_cerrar_pasos(cliente):
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol="supervisor")

    respuesta = cliente.post(
        f"/api/v1/ordenes-trabajo/{uuid4()}/pasos/{uuid4()}/cierre",
        json={"resultado_trabajo": "ejecutado", "tiempo_real_trabajado": "1", "descripcion_trabajo_realizado": "x"},
    )

    assert respuesta.status_code == 403


def test_supervisor_no_puede_gestionar_supervisores(cliente):
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol="supervisor")

    respuesta = cliente.get("/api/v1/supervisores")

    assert respuesta.status_code == 403
    assert respuesta.json()["detail"] == "Solo un Administrador puede realizar esta accion"


def test_health_responde_ok(cliente):
    assert cliente.get("/health").json() == {"status": "ok"}
