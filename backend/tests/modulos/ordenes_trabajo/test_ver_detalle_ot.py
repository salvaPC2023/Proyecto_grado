from datetime import datetime
from uuid import uuid4

import pytest

from src.modulos.acceso_roles.dominio.modelos import Tecnico
from src.modulos.ordenes_trabajo.aplicacion.ver_detalle_ot import OTNoEncontrada, SinAccesoAOT, ver_detalle_ot
from src.modulos.ordenes_trabajo.dominio.modelos import OrdenDeTrabajo
from tests.modulos.ordenes_trabajo.repositorios_falsos import RepositorioOrdenesTrabajoFalso, RepositorioTecnicosFalso

SUPERVISOR, OTRO_SUPERVISOR = uuid4(), uuid4()
TECNICO = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=uuid4(), profesion="mecanico")
OTRO_TECNICO = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=uuid4(), profesion="electrico")


@pytest.fixture
def escenario():
    ot = OrdenDeTrabajo(
        id=uuid4(), titulo="OT", tipo_de_orden="OE02", ubicacion_tecnica_id=uuid4(), tecnico_asignado_id=TECNICO.id, creado_por_id=uuid4(),
        descripcion="d", prioridad=2, estatus_equipo=True, estatus="asignada", fecha_inic_planif=datetime(2026, 10, 5, 8), fecha_fin_planif=datetime(2026, 10, 5, 12),
    )
    repositorio_ots = RepositorioOrdenesTrabajoFalso()
    repositorio_ots.crear(ot)
    repositorio_tecnicos = RepositorioTecnicosFalso(supervisor_de_tecnico={TECNICO.id: SUPERVISOR, OTRO_TECNICO.id: OTRO_SUPERVISOR}, tecnicos=[TECNICO, OTRO_TECNICO])
    return ot, repositorio_ots, repositorio_tecnicos


def test_el_tecnico_asignado_ve_su_ot(escenario):
    ot, repositorio_ots, repositorio_tecnicos = escenario

    resultado = ver_detalle_ot(ot.id, TECNICO.usuario_id, "tecnico", repositorio_ots, repositorio_tecnicos)

    assert resultado.id == ot.id


def test_otro_tecnico_no_puede_verla(escenario):
    ot, repositorio_ots, repositorio_tecnicos = escenario

    with pytest.raises(SinAccesoAOT):
        ver_detalle_ot(ot.id, OTRO_TECNICO.usuario_id, "tecnico", repositorio_ots, repositorio_tecnicos)


def test_el_supervisor_del_grupo_la_ve(escenario):
    ot, repositorio_ots, repositorio_tecnicos = escenario

    resultado = ver_detalle_ot(ot.id, SUPERVISOR, "supervisor", repositorio_ots, repositorio_tecnicos)

    assert resultado.id == ot.id


def test_un_supervisor_de_otro_grupo_no_puede_verla(escenario):
    ot, repositorio_ots, repositorio_tecnicos = escenario

    with pytest.raises(SinAccesoAOT):
        ver_detalle_ot(ot.id, OTRO_SUPERVISOR, "supervisor", repositorio_ots, repositorio_tecnicos)


def test_ot_inexistente_lanza_error(escenario):
    _, repositorio_ots, repositorio_tecnicos = escenario

    with pytest.raises(OTNoEncontrada):
        ver_detalle_ot(uuid4(), TECNICO.usuario_id, "tecnico", repositorio_ots, repositorio_tecnicos)


def test_ver_el_detalle_no_cambia_el_estado(escenario):
    ot, repositorio_ots, repositorio_tecnicos = escenario

    ver_detalle_ot(ot.id, TECNICO.usuario_id, "tecnico", repositorio_ots, repositorio_tecnicos)

    assert repositorio_ots.obtener_por_id(ot.id).estatus == "asignada"
