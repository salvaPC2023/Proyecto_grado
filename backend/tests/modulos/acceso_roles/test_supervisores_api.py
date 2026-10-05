from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from src.compartido.bd import get_db
from src.main import app
from src.modulos.acceso_roles.infraestructura import router
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioSupervisoresFalso, RepositorioUsuariosFalso, crear_supervisor, crear_usuario

DATOS = {
    "nombre": "Ana",
    "apellido_paterno": "Perez",
    "nombre_usuario": "aperez",
    "nombre_de_grupo": "Grupo 6",
    "horario_entrada": "07:00",
    "horario_salida": "15:00",
}


@pytest.fixture
def repositorios(monkeypatch):
    # el router usa los repositorios falsos en lugar de los de SQL
    usuarios = RepositorioUsuariosFalso()
    supervisores = RepositorioSupervisoresFalso()
    monkeypatch.setattr(router, "RepositorioUsuariosSQL", lambda db: usuarios)
    monkeypatch.setattr(router, "RepositorioSupervisoresSQL", lambda db: supervisores)
    return usuarios, supervisores


@pytest.fixture
def cliente(repositorios):
    app.dependency_overrides[get_db] = lambda: None
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol="administrador")
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_administrador_crea_un_supervisor(cliente):
    respuesta = cliente.post("/api/v1/supervisores", json=DATOS)

    assert respuesta.status_code == 201
    assert respuesta.json()["grupo_nombre"] == "Grupo 6"
    assert respuesta.json()["activo"] is True


def test_usuario_repetido_responde_409(cliente):
    cliente.post("/api/v1/supervisores", json=DATOS)

    respuesta = cliente.post("/api/v1/supervisores", json=DATOS)

    assert respuesta.status_code == 409


def test_entrada_igual_a_salida_responde_422(cliente):
    respuesta = cliente.post("/api/v1/supervisores", json={**DATOS, "horario_salida": "07:00"})

    assert respuesta.status_code == 422


def test_lista_los_supervisores(cliente):
    cliente.post("/api/v1/supervisores", json=DATOS)

    respuesta = cliente.get("/api/v1/supervisores")

    assert respuesta.status_code == 200
    assert [s["nombre_usuario"] for s in respuesta.json()] == ["aperez"]


def test_deshabilita_un_supervisor(cliente, repositorios):
    usuarios, supervisores = repositorios
    usuario = usuarios.crear(crear_usuario(nombre_usuario="frojas"))
    supervisor = supervisores.crear(crear_supervisor(usuario.id), grupo=None)

    respuesta = cliente.patch(f"/api/v1/supervisores/{supervisor.id}/estado", json={"activo": False})

    assert respuesta.status_code == 200
    assert usuarios.obtener_por_nombre_usuario("frojas").activo is False


def test_supervisor_inexistente_responde_404(cliente):
    respuesta = cliente.patch(f"/api/v1/supervisores/{uuid4()}/estado", json={"activo": False})

    assert respuesta.status_code == 404
