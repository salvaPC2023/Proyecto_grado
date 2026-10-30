from datetime import datetime
from decimal import Decimal
from uuid import uuid4

from src.modulos.ordenes_trabajo.aplicacion.cerrar_vencidas import cerrar_ots_vencidas
from src.modulos.ordenes_trabajo.dominio.modelos import DESCRIPCION_CIERRE_AUTOMATICO, CierrePaso, OrdenDeTrabajo, PasoOT
from tests.modulos.ordenes_trabajo.repositorios_falsos import RepositorioOrdenesTrabajoFalso

# Un día después del fin planificado, los PM01 sin cerrar se cierran solos como no ejecutados

FIN = datetime(2026, 10, 27, 16, 0)


def ot_con(cerrados: int, abiertos: int) -> OrdenDeTrabajo:
    ot_id = uuid4()
    pasos = [PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=None, descripcion="Seguridad", clave_control="PMNN")]
    for i in range(cerrados + abiertos):
        paso = PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=i + 1, descripcion="Paso", clave_control="PM01", horas_planificadas=Decimal("1"))
        if i < cerrados:
            paso.cierre = CierrePaso(uuid4(), paso.id, datetime(2026, 10, 27, 10), Decimal("1"), False, False, "ejecutado", "Hecho")
        pasos.append(paso)
    return OrdenDeTrabajo(
        id=ot_id, titulo="OT", tipo_de_orden="OE01", ubicacion_tecnica_id=uuid4(), tecnico_asignado_id=uuid4(),
        creado_por_id=uuid4(), prioridad=2, estatus_equipo=True, estatus="en_progreso" if cerrados else "asignada",
        fecha_inic_planif=datetime(2026, 10, 27, 8), fecha_fin_planif=FIN, pasos=pasos,
    )


def test_antes_del_plazo_no_se_cierra_nada():
    repositorio = RepositorioOrdenesTrabajoFalso()
    ot = repositorio.crear(ot_con(cerrados=0, abiertos=2))

    assert cerrar_ots_vencidas(datetime(2026, 10, 28, 15, 59), repositorio) == 0
    assert ot.estatus == "asignada"


def test_pasado_el_plazo_los_pm01_pendientes_quedan_no_ejecutados_y_la_ot_cerrada():
    repositorio = RepositorioOrdenesTrabajoFalso()
    ot = repositorio.crear(ot_con(cerrados=1, abiertos=2))

    cerrados = cerrar_ots_vencidas(datetime(2026, 10, 28, 16, 0), repositorio)

    assert cerrados == 2
    assert ot.estatus == "cerrada"
    assert ot.fecha_cierre == datetime(2026, 10, 28, 16, 0)
    automaticos = [p.cierre for p in ot.pasos[2:]]
    assert all(c.resultado_trabajo == "no_ejecutado" and c.tiempo_real_trabajado == 0 for c in automaticos)
    assert all(c.descripcion_trabajo_realizado == DESCRIPCION_CIERRE_AUTOMATICO for c in automaticos)
    assert ot.pasos[1].cierre.resultado_trabajo == "ejecutado"  # lo que cerró el técnico no se toca


def test_una_ot_ya_cerrada_no_se_toca():
    repositorio = RepositorioOrdenesTrabajoFalso()
    ot = repositorio.crear(ot_con(cerrados=2, abiertos=0))
    ot.estatus = "cerrada"

    assert cerrar_ots_vencidas(datetime(2026, 11, 5), repositorio) == 0
