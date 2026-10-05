from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

from src.modulos.acceso_roles.dominio.puertos import RepositorioTecnicos

from ..dominio.modelos import CierrePaso, OrdenDeTrabajo, ResultadoTrabajo
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
) -> OrdenDeTrabajo:
    ahora = ahora or datetime.now()

    ot = repositorio_ots.obtener_por_id(ot_id)
    if ot is None:
        raise OTNoEncontrada()
    tecnico = repositorio_tecnicos.obtener_por_usuario_id(tecnico_usuario_id)
    if tecnico is None or tecnico.id != ot.tecnico_asignado_id:
        raise SinAccesoAOT()
    if ot.estatus == "cerrada":
        raise OTYaCerrada()

    paso = next((p for p in ot.pasos if p.id == paso_id), None)
    if paso is None:
        raise PasoNoEncontrado()
    if paso.clave_control != "PM01":
        raise PasoNoRegistrable()
    if paso.cierre is not None:
        raise PasoYaCerrado()

    ejecutado = resultado_trabajo == "ejecutado"
    if (ejecutado and tiempo_real_trabajado <= 0) or (not ejecutado and tiempo_real_trabajado != 0):
        raise TiempoInvalido()
    if not descripcion_trabajo_realizado.strip():
        raise DescripcionVacia()
    if ahora.date() < ot.fecha_inic_planif.date():
        raise CierreAnticipado()

    # un PM01 no ejecutado también cuenta como cerrado
    quedan_pendientes = any(p.clave_control == "PM01" and p.cierre is None and p.id != paso.id for p in ot.pasos)
    es_el_ultimo = not quedan_pendientes

    cierre = CierrePaso(
        id=uuid4(),
        paso_ot_id=paso.id,
        fecha_hora_notificacion=ahora,
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
            fecha_cierre=ahora if es_el_ultimo else None,
        )
    except CierreDuplicado:
        raise PasoYaCerrado()
