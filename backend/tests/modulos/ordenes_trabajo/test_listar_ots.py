from datetime import date, datetime
from uuid import uuid4

from src.modulos.acceso_roles.dominio.modelos import Tecnico
from src.modulos.ordenes_trabajo.aplicacion.listar_ots_supervisor import listar_ots_supervisor
from src.modulos.ordenes_trabajo.aplicacion.listar_ots_tecnico import listar_ots_tecnico
from src.modulos.ordenes_trabajo.dominio.modelos import OrdenDeTrabajo
from tests.modulos.ordenes_trabajo.repositorios_falsos import RepositorioOrdenesTrabajoFalso, RepositorioTecnicosFalso

SUPERVISOR_A, SUPERVISOR_B = uuid4(), uuid4()
GRUPO_A, GRUPO_B = uuid4(), uuid4()
TECNICO_1 = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=GRUPO_A, profesion="mecanico")
TECNICO_2 = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=GRUPO_A, profesion="electrico")
TECNICO_3 = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=GRUPO_B, profesion="mecanico")


def _ot(tecnico: Tecnico) -> OrdenDeTrabajo:
    return OrdenDeTrabajo(
        id=uuid4(), titulo="OT", tipo_de_orden="OE02", ubicacion_tecnica_id=uuid4(), tecnico_asignado_id=tecnico.id, creado_por_id=uuid4(),
        descripcion="d", prioridad=2, estatus_equipo=True, estatus="asignada", fecha_inic_planif=datetime(2026, 10, 5, 8), fecha_fin_planif=datetime(2026, 10, 5, 12),
    )


def _repositorios():
    repositorio_ots = RepositorioOrdenesTrabajoFalso(grupo_de_tecnico={t.id: t.grupo_id for t in (TECNICO_1, TECNICO_2, TECNICO_3)})
    for tecnico in (TECNICO_1, TECNICO_1, TECNICO_2, TECNICO_3):
        repositorio_ots.crear(_ot(tecnico))
    repositorio_tecnicos = RepositorioTecnicosFalso(tecnicos=[TECNICO_1, TECNICO_2, TECNICO_3], grupo_de_supervisor={SUPERVISOR_A: GRUPO_A, SUPERVISOR_B: GRUPO_B})
    return repositorio_ots, repositorio_tecnicos


def test_el_tecnico_ve_solo_sus_ots():
    repositorio_ots, repositorio_tecnicos = _repositorios()

    ots = listar_ots_tecnico(TECNICO_1.usuario_id, repositorio_ots, repositorio_tecnicos)

    assert len(ots) == 2
    assert all(ot.tecnico_asignado_id == TECNICO_1.id for ot in ots)


def test_usuario_que_no_es_tecnico_no_ve_ots():
    repositorio_ots, repositorio_tecnicos = _repositorios()

    assert listar_ots_tecnico(uuid4(), repositorio_ots, repositorio_tecnicos) == []


def test_el_supervisor_ve_las_ots_de_todo_su_grupo_y_no_las_de_otro():
    repositorio_ots, repositorio_tecnicos = _repositorios()

    ots = listar_ots_supervisor(SUPERVISOR_A, repositorio_ots, repositorio_tecnicos)

    assert len(ots) == 3
    assert {ot.tecnico_asignado_id for ot in ots} == {TECNICO_1.id, TECNICO_2.id}


def test_supervisor_sin_grupo_no_ve_ots():
    repositorio_ots, repositorio_tecnicos = _repositorios()

    assert listar_ots_supervisor(uuid4(), repositorio_ots, repositorio_tecnicos) == []


def test_la_fecha_llega_al_repositorio():
    repositorio_ots, repositorio_tecnicos = _repositorios()

    listar_ots_tecnico(TECNICO_1.usuario_id, repositorio_ots, repositorio_tecnicos, fecha=date(2026, 10, 5))
    assert repositorio_ots.fecha_recibida == date(2026, 10, 5)

    listar_ots_supervisor(SUPERVISOR_A, repositorio_ots, repositorio_tecnicos, fecha=date(2026, 10, 6))
    assert repositorio_ots.fecha_recibida == date(2026, 10, 6)
