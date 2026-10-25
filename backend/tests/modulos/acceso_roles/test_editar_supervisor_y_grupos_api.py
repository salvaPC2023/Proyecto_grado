from datetime import time
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from src.compartido.bd import get_db
from src.main import app
from src.modulos.acceso_roles.dominio.modelos import Grupo, Supervisor
from src.modulos.acceso_roles.infraestructura import router
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario, repositorios_de_grupos


@pytest.fixture
def datos(monkeypatch):
    # el router usa los repositorios falsos en lugar de los de SQL
    usuario = crear_usuario(nombre_usuario="frojas")
    supervisor = Supervisor(id=uuid4(), usuario_id=usuario.id, horario_entrada=time(7), horario_salida=time(15))
    grupo = Grupo(id=uuid4(), nombre_de_grupo="Grupo 1", supervisor_id=supervisor.id, horario_entrada=time(7), horario_salida=time(15))
    vacio = Grupo(id=uuid4(), nombre_de_grupo="Grupo por error", supervisor_id=None, horario_entrada=time(7), horario_salida=time(15))
    con_tecnicos = Grupo(id=uuid4(), nombre_de_grupo="Grupo 2", supervisor_id=None, horario_entrada=time(7), horario_salida=time(15))
    supervisores, grupos = repositorios_de_grupos([supervisor], [grupo, vacio, con_tecnicos], tecnicos_por_grupo={con_tecnicos.id: 2})
    usuarios = RepositorioUsuariosFalso([usuario])
    monkeypatch.setattr(router, "RepositorioUsuariosSQL", lambda db: usuarios)
    monkeypatch.setattr(router, "RepositorioSupervisoresSQL", lambda db: supervisores)
    monkeypatch.setattr(router, "RepositorioGruposSQL", lambda db: grupos)
    return {"supervisor": supervisor, "grupo": grupo, "vacio": vacio, "con_tecnicos": con_tecnicos}


@pytest.fixture
def cliente(datos):
    app.dependency_overrides[get_db] = lambda: None
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol="administrador")
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_edita_turno_y_area_del_supervisor(cliente, datos):
    respuesta = cliente.patch(
        f"/api/v1/supervisores/{datos['supervisor'].id}",
        json={"horario_entrada": "23:00", "horario_salida": "07:00", "area_designada": "Procesos"},
    )

    assert respuesta.status_code == 200
    assert respuesta.json()["horario_entrada"] == "23:00:00"
    assert respuesta.json()["area_designada"] == "Procesos"
    assert respuesta.json()["grupo_id"] == str(datos["grupo"].id)


def test_entrada_igual_a_salida_responde_422(cliente, datos):
    respuesta = cliente.patch(
        f"/api/v1/supervisores/{datos['supervisor'].id}",
        json={"horario_entrada": "07:00", "horario_salida": "07:00"},
    )

    assert respuesta.status_code == 422


def test_supervisor_inexistente_responde_404(cliente):
    respuesta = cliente.patch(f"/api/v1/supervisores/{uuid4()}", json={"horario_entrada": "07:00", "horario_salida": "15:00"})

    assert respuesta.status_code == 404


def test_borra_un_grupo_vacio(cliente, datos):
    respuesta = cliente.delete(f"/api/v1/grupos/{datos['vacio'].id}")

    assert respuesta.status_code == 204


def test_no_borra_un_grupo_con_tecnicos_y_dice_por_que(cliente, datos):
    respuesta = cliente.delete(f"/api/v1/grupos/{datos['con_tecnicos'].id}")

    assert respuesta.status_code == 409
    assert "2 técnicos" in respuesta.json()["detail"]


def test_solo_el_administrador_borra_grupos(cliente, datos):
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=uuid4(), rol="supervisor")

    respuesta = cliente.delete(f"/api/v1/grupos/{datos['vacio'].id}")

    assert respuesta.status_code == 403
