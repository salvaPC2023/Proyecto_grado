from datetime import datetime, timedelta
from decimal import Decimal
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from src.compartido.bd import get_db
from src.main import app
from src.modulos.acceso_roles.dominio.modelos import Tecnico
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual
from src.modulos.ordenes_trabajo.dominio.modelos import OrdenDeTrabajo, PasoOT
from src.modulos.ordenes_trabajo.infraestructura import router
from tests.modulos.ordenes_trabajo.repositorios_falsos import RepositorioOrdenesTrabajoFalso, RepositorioTecnicosFalso, RepositorioUbicacionesFalso

TECNICO = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=uuid4(), profesion="mecanico")
CIERRE = {"resultado_trabajo": "ejecutado", "tiempo_real_trabajado": "1.5", "descripcion_trabajo_realizado": "Se cambió el rodamiento"}


@pytest.fixture
def ot():
    ot_id = uuid4()
    ayer = datetime.now() - timedelta(days=1)
    return OrdenDeTrabajo(
        id=ot_id, titulo="Cambiar rodamiento", tipo_de_orden="OE01", ubicacion_tecnica_id=uuid4(), tecnico_asignado_id=TECNICO.id, creado_por_id=uuid4(),
        descripcion="d", prioridad=2, estatus_equipo=False, estatus="asignada", fecha_inic_planif=ayer, fecha_fin_planif=ayer + timedelta(days=2),
        pasos=[
            PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=1, descripcion="Piense", clave_control="PMNN"),
            PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=4, descripcion="Desmontar", clave_control="PM01", horas_planificadas=Decimal("1")),
        ],
    )


@pytest.fixture
def cliente(monkeypatch, ot):
    # el router usa los repositorios falsos en lugar de los de SQL
    repositorio_ots = RepositorioOrdenesTrabajoFalso()
    repositorio_ots.crear(ot)
    monkeypatch.setattr(router, "RepositorioOrdenesTrabajoSQL", lambda db: repositorio_ots)
    monkeypatch.setattr(router, "RepositorioTecnicosSQL", lambda db: RepositorioTecnicosFalso(tecnicos=[TECNICO]))
    monkeypatch.setattr(router, "RepositorioUbicacionesTecnicasSQL", lambda db: RepositorioUbicacionesFalso([]))
    app.dependency_overrides[get_db] = lambda: None
    app.dependency_overrides[obtener_usuario_actual] = lambda: UsuarioAutenticado(id=TECNICO.usuario_id, rol="tecnico")
    yield TestClient(app)
    app.dependency_overrides.clear()


def _url(ot, paso):
    return f"/api/v1/ordenes-trabajo/{ot.id}/pasos/{paso.id}/cierre"


def test_tecnico_cierra_el_unico_pm01_y_la_ot_queda_cerrada(cliente, ot):
    respuesta = cliente.post(_url(ot, ot.pasos[1]), json=CIERRE)

    assert respuesta.status_code == 201
    assert respuesta.json()["estatus"] == "cerrada"
    assert respuesta.json()["pasos"][1]["cierre"]["trabajo_finalizado"] is True


def test_paso_ya_cerrado_responde_409(cliente, ot):
    cliente.post(_url(ot, ot.pasos[1]), json=CIERRE)

    respuesta = cliente.post(_url(ot, ot.pasos[1]), json=CIERRE)

    assert respuesta.status_code == 409


def test_paso_pmnn_responde_422(cliente, ot):
    respuesta = cliente.post(_url(ot, ot.pasos[0]), json=CIERRE)

    assert respuesta.status_code == 422


def test_tiempo_cero_en_un_paso_ejecutado_responde_422(cliente, ot):
    respuesta = cliente.post(_url(ot, ot.pasos[1]), json={**CIERRE, "tiempo_real_trabajado": "0"})

    assert respuesta.status_code == 422


def test_ot_inexistente_responde_404(cliente, ot):
    respuesta = cliente.post(f"/api/v1/ordenes-trabajo/{uuid4()}/pasos/{ot.pasos[1].id}/cierre", json=CIERRE)

    assert respuesta.status_code == 404


def test_tecnico_ve_sus_ots(cliente, ot):
    respuesta = cliente.get("/api/v1/ordenes-trabajo/mis-ots")

    assert respuesta.status_code == 200
    assert [o["id"] for o in respuesta.json()] == [str(ot.id)]


def test_tecnico_ve_el_detalle_de_su_ot(cliente, ot):
    respuesta = cliente.get(f"/api/v1/ordenes-trabajo/{ot.id}")

    assert respuesta.status_code == 200
    assert respuesta.json()["estatus"] == "asignada"  # abrir el detalle no cambia el estado


def test_detalle_de_ot_inexistente_responde_404(cliente):
    respuesta = cliente.get(f"/api/v1/ordenes-trabajo/{uuid4()}")

    assert respuesta.status_code == 404
