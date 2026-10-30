from datetime import datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

from src.modulos.acceso_roles.dominio.puertos import RepositorioTecnicos

from ..dominio.modelos import MAX_DESCRIPCION_CIERRE, MAX_HORAS_POR_PASO, CierrePaso, OrdenDeTrabajo, ResultadoTrabajo
from ..dominio.puertos import CierreDuplicado, RepositorioOrdenesTrabajo
from .ver_detalle_ot import OTNoEncontrada, SinAccesoAOT


class PasoNoEncontrado(Exception):
    pass


class PasoNoRegistrable(Exception):
    pass


class PasoYaCerrado(Exception):
    pass


class OTYaCerrada(Exception):
    pass


class TiempoInvalido(Exception):
    pass


class DescripcionVacia(Exception):
    pass


class CierreAnticipado(Exception):
    pass


class FechaCierreFutura(Exception):
    pass


class DescripcionMuyLarga(Exception):
    pass


class OTVencida(Exception):
    """Pasó el plazo para cerrar: los pasos pendientes se cierran solos como no ejecutados"""


# margen para que un reloj del celular un poco adelantado no rechace el cierre
TOLERANCIA_RELOJ = timedelta(minutes=5)


def registrar_cierre_paso(
    ot_id: UUID,
    paso_id: UUID,
    tecnico_usuario_id: UUID,
    resultado_trabajo: ResultadoTrabajo,
    tiempo_real_trabajado: Decimal,
    descripcion_trabajo_realizado: str,
    repositorio_ots: RepositorioOrdenesTrabajo,
    repositorio_tecnicos: RepositorioTecnicos,
    ahora: datetime | None = None,
    cierre_id: UUID | None = None,
    fecha_hora_cierre: datetime | None = None,
) -> OrdenDeTrabajo:
    """cierre_id y fecha_hora_cierre los envía el celular: así un cierre hecho sin conexión conserva
    su hora real, y si se reenvía con el mismo id no se duplica (se devuelve la OT tal como quedó)"""
    ahora = ahora or datetime.now()
    momento = fecha_hora_cierre or ahora

    ot = repositorio_ots.obtener_por_id(ot_id)
    if ot is None:
        raise OTNoEncontrada()
    tecnico = repositorio_tecnicos.obtener_por_usuario_id(tecnico_usuario_id)
    if tecnico is None or tecnico.id != ot.tecnico_asignado_id:
        raise SinAccesoAOT()

    paso = next((p for p in ot.pasos if p.id == paso_id), None)
    if paso is None:
        raise PasoNoEncontrado()
    # reenvío de un cierre que ya llegó (la cola del celular no recibió la respuesta): no es un error.
    # Va antes de revisar si la OT está cerrada, porque el cierre reenviado pudo ser el que la cerró
    if _ya_registrado(paso, cierre_id):
        return ot
    if ot.estatus == "cerrada":
        raise OTYaCerrada()
    if paso.clave_control != "PM01":
        raise PasoNoRegistrable()
    if paso.cierre is not None:
        raise PasoYaCerrado()

    ejecutado = resultado_trabajo == "ejecutado"
    if (ejecutado and tiempo_real_trabajado <= 0) or (not ejecutado and tiempo_real_trabajado != 0):
        raise TiempoInvalido("Si el trabajo se ejecutó, el tiempo debe ser mayor a 0; si no se ejecutó, debe ser 0")
    if tiempo_real_trabajado > MAX_HORAS_POR_PASO:
        raise TiempoInvalido(f"Un paso no puede registrar más de {MAX_HORAS_POR_PASO} horas trabajadas")
    if not descripcion_trabajo_realizado.strip():
        raise DescripcionVacia()
    if len(descripcion_trabajo_realizado.strip()) > MAX_DESCRIPCION_CIERRE:
        raise DescripcionMuyLarga()
    if momento > ahora + TOLERANCIA_RELOJ:
        raise FechaCierreFutura()
    if momento.date() < ot.fecha_inic_planif.date():
        raise CierreAnticipado()
    # se compara con la hora en que el técnico cerró: un cierre hecho a tiempo sin señal se acepta al llegar
    if momento >= ot.vencimiento:
        raise OTVencida()

    # un PM01 no ejecutado también cuenta como cerrado
    quedan_pendientes = any(p.clave_control == "PM01" and p.cierre is None and p.id != paso.id for p in ot.pasos)
    es_el_ultimo = not quedan_pendientes

    cierre = CierrePaso(
        id=cierre_id or uuid4(),
        paso_ot_id=paso.id,
        fecha_hora_notificacion=momento,
        tiempo_real_trabajado=tiempo_real_trabajado,
        trabajo_finalizado=es_el_ultimo,
        sin_trabajo_realizado=not ejecutado,
        resultado_trabajo=resultado_trabajo,
        descripcion_trabajo_realizado=descripcion_trabajo_realizado.strip(),
    )
    try:
        return repositorio_ots.registrar_cierre(
            ot.id,
            cierre,
            estatus="cerrada" if es_el_ultimo else "en_progreso",
            fecha_cierre=momento if es_el_ultimo else None,
        )
    except CierreDuplicado:
        # dos envíos del mismo cierre llegaron a la vez: el segundo devuelve lo que guardó el primero
        ot = repositorio_ots.obtener_por_id(ot_id)
        paso = next((p for p in ot.pasos if p.id == paso_id), None)
        if paso is not None and _ya_registrado(paso, cierre_id):
            return ot
        raise PasoYaCerrado()


def _ya_registrado(paso, cierre_id: UUID | None) -> bool:
    return cierre_id is not None and paso.cierre is not None and paso.cierre.id == cierre_id
