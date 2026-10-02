"""Solo el Supervisor gestiona tecnicos: un Tecnico recibe 403 en los tres endpoints.

No toca la BD: se reemplaza obtener_usuario_actual por un usuario fijo, y el 403 lo
lanza requerir_supervisor antes de llegar al caso de uso.
"""

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from src.main import app
from src.modulos.acceso_roles.infraestructura.dependencias import (
    UsuarioAutenticado,
    obtener_usuario_actual,
)


@pytest.fixture
def cliente_tecnico():
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(
        id=uuid4(), rol="tecnico"
    )
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.mark.parametrize(
    "metodo, ruta, cuerpo",
    [
        ("get", "/api/v1/tecnicos", None),
        (
            "post",
            "/api/v1/tecnicos",
            {"nombre": "x", "apellido_paterno": "x", "nombre_usuario": "x", "profesion": "mecanico"},
        ),
        ("patch", f"/api/v1/tecnicos/{uuid4()}/estado", {"activo": False}),
    ],
)
def test_tecnico_no_puede_gestionar_tecnicos(cliente_tecnico, metodo, ruta, cuerpo):
    respuesta = cliente_tecnico.request(metodo, ruta, json=cuerpo)

    assert respuesta.status_code == 403
    assert respuesta.json()["detail"] == "Solo un Supervisor puede realizar esta accion"
