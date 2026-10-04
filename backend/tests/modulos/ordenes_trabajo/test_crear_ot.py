from datetime import datetime
from decimal import Decimal
from uuid import uuid4

import pytest

from src.modulos.ordenes_trabajo.aplicacion.crear_ot import FechasInvalidas, HorasInvalidas, PasoSolicitado, PrioridadInvalida, SinPasoPM01, TecnicoFueraDeGrupo, UbicacionNoEncontrada, crear_ot
from src.modulos.ordenes_trabajo.dominio.modelos import PASOS_SEGURIDAD
from src.modulos.ubicaciones_tecnicas.dominio.modelos import UbicacionTecnica
from tests.modulos.ordenes_trabajo.repositorios_falsos import RepositorioOrdenesTrabajoFalso, RepositorioTecnicosFalso, RepositorioUbicacionesFalso


SUPERVISOR = uuid4()
OTRO_SUPERVISOR = uuid4()
TECNICO = uuid4()
TECNICO_DE_OTRO_GRUPO = uuid4()
UBICACION = UbicacionTecnica(id=uuid4(), sector="Embotellado", subsector="Area 1", sistema="Llenadora")


@pytest.fixture
def repositorios():
    return {
        "repositorio_ots": RepositorioOrdenesTrabajoFalso(),
        "repositorio_ubicaciones": RepositorioUbicacionesFalso([UBICACION]),
        "repositorio_tecnicos": RepositorioTecnicosFalso(supervisor_de_tecnico={TECNICO: SUPERVISOR, TECNICO_DE_OTRO_GRUPO: OTRO_SUPERVISOR}),
    }


def pm01(horas="2.5", descripcion="Cambiar rodamiento"):
    return PasoSolicitado(descripcion=descripcion, clave_control="PM01", horas_planificadas=Decimal(horas) if horas is not None else None)


def pmnn(descripcion="Revisar guardas", horas=None):
    return PasoSolicitado(descripcion=descripcion, clave_control="PMNN", horas_planificadas=Decimal(horas) if horas is not None else None)


def _crear(repositorios, **cambios):
    datos = dict(
        titulo="Sobrecalentamiento de transformador",
        tipo_de_orden="OE01",
        ubicacion_tecnica_id=UBICACION.id,
        tecnico_asignado_id=TECNICO,
        descripcion="Revisar y corregir temperatura",
        prioridad=1,
        estatus_equipo=False,
        fecha_inic_planif=datetime(2026, 10, 10, 8, 0),
        fecha_fin_planif=datetime(2026, 10, 10, 12, 0),
        pasos=[pm01()],
        supervisor_usuario_id=SUPERVISOR,
    )
    datos.update(cambios)
    return crear_ot(**datos, **repositorios)


def test_crea_la_ot_asignada_y_la_guarda(repositorios):
    ot = _crear(repositorios)

    assert ot.estatus == "asignada"
    assert ot.creado_por_id == SUPERVISOR
    assert repositorios["repositorio_ots"].obtener_por_id(ot.id) is ot


def test_los_3_primeros_pasos_son_los_de_seguridad(repositorios):
    ot = _crear(repositorios)

    assert tuple(p.descripcion for p in ot.pasos[:3]) == PASOS_SEGURIDAD
    assert all(p.clave_control == "PMNN" and p.horas_planificadas is None for p in ot.pasos[:3])


def test_los_pasos_del_supervisor_empiezan_en_el_4(repositorios):
    ot = _crear(repositorios, pasos=[pmnn(), pm01()])

    assert [p.numero_paso for p in ot.pasos] == [1, 2, 3, 4, 5]
    assert [p.clave_control for p in ot.pasos[3:]] == ["PMNN", "PM01"]
    assert all(p.ot_id == ot.id for p in ot.pasos)


@pytest.mark.parametrize("prioridad", [0, 5])
def test_prioridad_fuera_de_1_a_4_lanza_error(repositorios, prioridad):
    with pytest.raises(PrioridadInvalida):
        _crear(repositorios, prioridad=prioridad)


def test_fecha_fin_anterior_a_la_de_inicio_lanza_error(repositorios):
    with pytest.raises(FechasInvalidas):
        _crear(repositorios, fecha_inic_planif=datetime(2026, 10, 10, 12, 0), fecha_fin_planif=datetime(2026, 10, 10, 8, 0))


def test_se_permite_una_fecha_de_inicio_en_el_pasado(repositorios):
    ot = _crear(repositorios, fecha_inic_planif=datetime(2020, 1, 1, 8, 0), fecha_fin_planif=datetime(2020, 1, 1, 12, 0))

    assert ot.fecha_inic_planif.year == 2020


def test_sin_paso_pm01_lanza_error(repositorios):
    with pytest.raises(SinPasoPM01):
        _crear(repositorios, pasos=[pmnn()])


@pytest.mark.parametrize("horas", [None, "0"])
def test_pm01_sin_horas_o_con_cero_lanza_error(repositorios, horas):
    with pytest.raises(HorasInvalidas):
        _crear(repositorios, pasos=[pm01(horas=horas)])


def test_pmnn_con_horas_lanza_error(repositorios):
    with pytest.raises(HorasInvalidas):
        _crear(repositorios, pasos=[pm01(), pmnn(horas="1")])


def test_ubicacion_inexistente_lanza_error(repositorios):
    with pytest.raises(UbicacionNoEncontrada):
        _crear(repositorios, ubicacion_tecnica_id=uuid4())


def test_tecnico_de_otro_grupo_lanza_error(repositorios):
    with pytest.raises(TecnicoFueraDeGrupo):
        _crear(repositorios, tecnico_asignado_id=TECNICO_DE_OTRO_GRUPO)


def test_si_una_regla_falla_no_se_guarda_nada(repositorios):
    with pytest.raises(TecnicoFueraDeGrupo):
        _crear(repositorios, tecnico_asignado_id=TECNICO_DE_OTRO_GRUPO)

    assert repositorios["repositorio_ots"].ots == {}
