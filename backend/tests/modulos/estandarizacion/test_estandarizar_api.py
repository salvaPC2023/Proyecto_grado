from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from src.main import app
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual
from src.modulos.estandarizacion.dominio.puertos import ServicioEstandarizacion, ServicioNoDisponible, TiempoAgotado
from src.modulos.estandarizacion.infraestructura import router

URL = "/api/v1/descripciones/estandarizar"


class ServicioQueFalla(ServicioEstandarizacion):
    def __init__(self, error):
        self.error = error

    def estandarizar(self, texto):
        raise self.error


class ServicioQueResponde(ServicioEstandarizacion):
    def estandarizar(self, texto):
        return "Equipo intervenido: Motor\n\nActividades realizadas:\n- Se cambió el rodamiento"


@pytest.fixture
def cliente():
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol="tecnico")
    yield TestClient(app)
    app.dependency_overrides.clear()


def _usar(monkeypatch, servicio):
    # el endpoint usa el servicio indicado en lugar de llamar a OpenAI
    monkeypatch.setattr(router, "ServicioEstandarizacionOpenAI", lambda: servicio)


def test_devuelve_el_texto_estandarizado(cliente, monkeypatch):
    _usar(monkeypatch, ServicioQueResponde())

    respuesta = cliente.post(URL, json={"texto": "cambie el rodamiento del motor"})

    assert respuesta.status_code == 200
    assert respuesta.json()["texto_estandarizado"].startswith("Equipo intervenido:")


def test_si_el_modelo_no_responde_a_tiempo_responde_504(cliente, monkeypatch):
    _usar(monkeypatch, ServicioQueFalla(TiempoAgotado()))

    respuesta = cliente.post(URL, json={"texto": "cambie el rodamiento"})

    assert respuesta.status_code == 504
    assert "texto original" in respuesta.json()["detail"]


def test_si_el_proveedor_falla_responde_503(cliente, monkeypatch):
    _usar(monkeypatch, ServicioQueFalla(ServicioNoDisponible()))

    respuesta = cliente.post(URL, json={"texto": "cambie el rodamiento"})

    assert respuesta.status_code == 503


def test_solo_el_tecnico_puede_estandarizar(monkeypatch):
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol="supervisor")
    _usar(monkeypatch, ServicioQueResponde())
    try:
        respuesta = TestClient(app).post(URL, json={"texto": "cambie el rodamiento"})
    finally:
        app.dependency_overrides.clear()

    assert respuesta.status_code == 403
