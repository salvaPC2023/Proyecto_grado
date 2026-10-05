from datetime import datetime
from decimal import Decimal
from uuid import uuid4

import pytest

from src.modulos.acceso_roles.dominio.modelos import Tecnico
from src.modulos.ordenes_trabajo.aplicacion.registrar_cierre_paso import (
    CierreAnticipado,
    DescripcionVacia,
    OTYaCerrada,
    PasoNoEncontrado,
    PasoNoRegistrable,
    PasoYaCerrado,
    TiempoInvalido,
    registrar_cierre_paso,
)
from src.modulos.ordenes_trabajo.aplicacion.ver_detalle_ot import OTNoEncontrada, SinAccesoAOT
from src.modulos.ordenes_trabajo.dominio.modelos import OrdenDeTrabajo, PasoOT
from tests.modulos.ordenes_trabajo.repositorios_falsos import RepositorioOrdenesTrabajoFalso, RepositorioTecnicosFalso

TECNICO = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=uuid4(), profesion="mecanico")
OTRO_TECNICO = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=uuid4(), profesion="electrico")
DIA_DE_INICIO = datetime(2026, 10, 5, 10, 0)


@pytest.fixture
def ot():
    # un paso de seguridad (PMNN) y dos PM01 abiertos
    ot_id = uuid4()
    return OrdenDeTrabajo(
        id=ot_id, titulo="Cambiar rodamiento", tipo_de_orden="OE01", ubicacion_tecnica_id=uuid4(), tecnico_asignado_id=TECNICO.id, creado_por_id=uuid4(),
        descripcion="d", prioridad=2, estatus_equipo=False, estatus="asignada", fecha_inic_planif=datetime(2026, 10, 5, 8), fecha_fin_planif=datetime(2026, 10, 5, 12),
        pasos=[
            PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=1, descripcion="Piense", clave_control="PMNN"),
            PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=4, descripcion="Desmontar", clave_control="PM01", horas_planificadas=Decimal("1")),
            PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=5, descripcion="Montar", clave_control="PM01", horas_planificadas=Decimal("1")),
        ],
    )


def _cerrar(ot, paso, resultado="ejecutado", tiempo="1.5", descripcion="Se cambió el rodamiento", usuario=TECNICO.usuario_id, ahora=DIA_DE_INICIO):
    repositorio_ots = RepositorioOrdenesTrabajoFalso()
    repositorio_ots.crear(ot)
    return registrar_cierre_paso(
        ot.id, paso.id, usuario, resultado, Decimal(tiempo), descripcion,
        repositorio_ots, RepositorioTecnicosFalso(tecnicos=[TECNICO, OTRO_TECNICO]), ahora=ahora,
    )


def test_el_primer_cierre_pasa_la_ot_a_en_progreso(ot):
    resultado = _cerrar(ot, ot.pasos[1])

    assert resultado.estatus == "en_progreso"
    assert resultado.fecha_cierre is None
    assert resultado.pasos[1].cierre.trabajo_finalizado is False


def test_cerrar_el_ultimo_pm01_cierra_la_ot(ot):
    _cerrar(ot, ot.pasos[1])

    resultado = _cerrar(ot, ot.pasos[2])

    assert resultado.estatus == "cerrada"
    assert resultado.fecha_cierre == DIA_DE_INICIO
    assert resultado.pasos[2].cierre.trabajo_finalizado is True


def test_un_pm01_no_ejecutado_cuenta_como_cerrado(ot):
    _cerrar(ot, ot.pasos[1])

    resultado = _cerrar(ot, ot.pasos[2], resultado="no_ejecutado", tiempo="0")

    assert resultado.estatus == "cerrada"
    assert resultado.pasos[2].cierre.sin_trabajo_realizado is True  # lo calcula el sistema


@pytest.mark.parametrize("resultado, tiempo", [("ejecutado", "0"), ("no_ejecutado", "1")])
def test_tiempo_que_no_corresponde_al_resultado_lanza_error(ot, resultado, tiempo):
    with pytest.raises(TiempoInvalido):
        _cerrar(ot, ot.pasos[1], resultado=resultado, tiempo=tiempo)


def test_descripcion_vacia_lanza_error(ot):
    with pytest.raises(DescripcionVacia):
        _cerrar(ot, ot.pasos[1], descripcion="   ")


def test_paso_pmnn_lanza_error(ot):
    with pytest.raises(PasoNoRegistrable):
        _cerrar(ot, ot.pasos[0])


def test_paso_ya_cerrado_lanza_error(ot):
    _cerrar(ot, ot.pasos[1])

    with pytest.raises(PasoYaCerrado):
        _cerrar(ot, ot.pasos[1])


def test_ot_cerrada_lanza_error(ot):
    ot.estatus = "cerrada"

    with pytest.raises(OTYaCerrada):
        _cerrar(ot, ot.pasos[1])


def test_tecnico_no_asignado_lanza_error(ot):
    with pytest.raises(SinAccesoAOT):
        _cerrar(ot, ot.pasos[1], usuario=OTRO_TECNICO.usuario_id)


def test_cerrar_antes_del_dia_de_inicio_lanza_error(ot):
    with pytest.raises(CierreAnticipado):
        _cerrar(ot, ot.pasos[1], ahora=datetime(2026, 10, 4, 23, 0))


def test_se_permite_cerrar_con_atraso(ot):
    resultado = _cerrar(ot, ot.pasos[1], ahora=datetime(2026, 10, 9, 8, 0))

    assert resultado.estatus == "en_progreso"


def test_ot_inexistente_lanza_error(ot):
    with pytest.raises(OTNoEncontrada):
        registrar_cierre_paso(uuid4(), uuid4(), TECNICO.usuario_id, "ejecutado", Decimal("1"), "d", RepositorioOrdenesTrabajoFalso(), RepositorioTecnicosFalso(tecnicos=[TECNICO]))


def test_paso_de_otra_ot_lanza_error(ot):
    paso_ajeno = PasoOT(id=uuid4(), ot_id=uuid4(), numero_paso=4, descripcion="x", clave_control="PM01")

    with pytest.raises(PasoNoEncontrado):
        _cerrar(ot, paso_ajeno)
