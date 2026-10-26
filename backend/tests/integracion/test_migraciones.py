from datetime import datetime, time

import pytest
from alembic import command
from sqlalchemy import inspect, text

from tests.integracion.conftest import configuracion_alembic, url_de_prueba

pytestmark = pytest.mark.integracion


def pasos_en_bd(sesiones) -> list[int | None]:
    with sesiones() as sesion:
        return sesion.execute(text("SELECT numero_paso FROM pasos_de_ots ORDER BY numero_paso NULLS FIRST")).scalars().all()


def test_la_migracion_0003_renumera_los_pasos_en_las_dos_direcciones(api, sesiones, motor):
    # una OT creada con el esquema actual: 3 pasos de seguridad sin número y 2 del supervisor
    _, supervisor = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    tecnico, _ = api.crear_tecnico(supervisor, "Carlos", "Mamani")
    hoy = datetime.now().date()
    api.cliente.post("/api/v1/ordenes-trabajo", headers=supervisor, json={
        "titulo": "Cambio de filtro", "tipo_de_orden": "OE01", "ubicacion_tecnica_id": api.crear_ubicacion()["id"],
        "tecnico_asignado_id": tecnico["id"], "prioridad": 3, "estatus_equipo": True,
        "fecha_inic_planif": datetime.combine(hoy, time(8)).isoformat(),
        "fecha_fin_planif": datetime.combine(hoy, time(12)).isoformat(),
        "pasos": [
            {"descripcion": "Desmontar", "clave_control": "PM01", "horas_planificadas": "1"},
            {"descripcion": "Montar", "clave_control": "PM01", "horas_planificadas": "1"},
        ],
    })
    assert pasos_en_bd(sesiones) == [None, None, None, 1, 2]

    config = configuracion_alembic(url_de_prueba())
    try:
        command.downgrade(config, "0002")
        # antes de la 0003: todos los pasos numerados, los del supervisor desde el 4, y la OT con descripción
        assert pasos_en_bd(sesiones) == [1, 2, 3, 4, 5]
        assert "descripcion" in {c["name"] for c in inspect(motor).get_columns("ordenes_de_trabajo")}
    finally:
        command.upgrade(config, "head")  # las demás pruebas necesitan el esquema actual

    assert pasos_en_bd(sesiones) == [None, None, None, 1, 2]
    assert "descripcion" not in {c["name"] for c in inspect(motor).get_columns("ordenes_de_trabajo")}
