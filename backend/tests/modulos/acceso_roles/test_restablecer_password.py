from datetime import time
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from src.compartido.bd import get_db
from src.compartido.configuracion import settings
from src.compartido.seguridad import verificar_password
from src.main import app
from src.modulos.acceso_roles.aplicacion.restablecer_password import CuentaNoEncontrada, restablecer_password
from src.modulos.acceso_roles.dominio.modelos import Supervisor, Tecnico
from src.modulos.acceso_roles.infraestructura import router
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioSupervisoresFalso, RepositorioTecnicosFalso, RepositorioUsuariosFalso, crear_usuario

# Prueba con usuarios del 23/10/2026: si un técnico o supervisor olvida su contraseña,
# el administrador la devuelve a la inicial y la persona elige una nueva al entrar


def test_vuelve_a_la_password_inicial_y_obliga_a_cambiarla():
    usuario = crear_usuario(password="MiClaveSegura1!")
    repositorio = RepositorioUsuariosFalso([usuario])

    restablecer_password(usuario.id, repositorio)

    assert verificar_password(settings.default_technician_password, usuario.password_hash)
    assert not verificar_password("MiClaveSegura1!", usuario.password_hash)
    assert usuario.debe_cambiar_password


def test_no_restablece_la_cuenta_del_administrador():
    admin = crear_usuario(nombre_usuario="admin")
    admin.rol = "admin"

    with pytest.raises(CuentaNoEncontrada):
        restablecer_password(admin.id, RepositorioUsuariosFalso([admin]))


def test_cuenta_inexistente():
    with pytest.raises(CuentaNoEncontrada):
        restablecer_password(uuid4(), RepositorioUsuariosFalso())


# --- API ---

@pytest.fixture
def datos(monkeypatch):
    # el router usa los repositorios falsos en lugar de los de SQL
    usuario_supervisor = crear_usuario(nombre_usuario="frojas")
    usuario_tecnico = crear_usuario(nombre_usuario="jperez")
    supervisor = Supervisor(id=uuid4(), usuario_id=usuario_supervisor.id, horario_entrada=time(7), horario_salida=time(15))
    tecnico = Tecnico(id=uuid4(), usuario_id=usuario_tecnico.id, grupo_id=uuid4(), profesion="electrico")
    usuarios = RepositorioUsuariosFalso([usuario_supervisor, usuario_tecnico])
    tecnicos = RepositorioTecnicosFalso([tecnico])
    monkeypatch.setattr(router, "RepositorioUsuariosSQL", lambda db: usuarios)
    monkeypatch.setattr(router, "RepositorioSupervisoresSQL", lambda db: RepositorioSupervisoresFalso([supervisor]))
    monkeypatch.setattr(router, "RepositorioTecnicosSQL", lambda db: tecnicos)
    return {"supervisor": supervisor, "tecnico": tecnico, "usuario_tecnico": usuario_tecnico}


def _cliente(rol):
    app.dependency_overrides[get_db] = lambda: None
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol=rol)
    return TestClient(app)


@pytest.fixture
def cliente(datos):
    yield _cliente("administrador")
    app.dependency_overrides.clear()


def test_el_administrador_restablece_a_un_supervisor(cliente, datos):
    respuesta = cliente.post(f"/api/v1/supervisores/{datos['supervisor'].id}/restablecer-password")

    assert respuesta.status_code == 200
    assert respuesta.json() == {"nombre_usuario": "frojas", "password_inicial": settings.default_technician_password}


def test_el_administrador_restablece_a_un_tecnico(cliente, datos):
    respuesta = cliente.post(f"/api/v1/tecnicos/{datos['tecnico'].id}/restablecer-password")

    assert respuesta.status_code == 200
    assert respuesta.json()["nombre_usuario"] == "jperez"
    assert datos["usuario_tecnico"].debe_cambiar_password


def test_tecnico_inexistente_responde_404(cliente):
    assert cliente.post(f"/api/v1/tecnicos/{uuid4()}/restablecer-password").status_code == 404


def test_el_administrador_ve_los_tecnicos_de_un_grupo(cliente, datos):
    respuesta = cliente.get(f"/api/v1/grupos/{datos['tecnico'].grupo_id}/tecnicos")

    assert respuesta.status_code == 200
    assert [t["nombre_usuario"] for t in respuesta.json()] == ["jperez"]


def test_un_supervisor_no_puede_restablecer(datos):
    cliente = _cliente("supervisor")
    try:
        assert cliente.post(f"/api/v1/tecnicos/{datos['tecnico'].id}/restablecer-password").status_code == 403
    finally:
        app.dependency_overrides.clear()
