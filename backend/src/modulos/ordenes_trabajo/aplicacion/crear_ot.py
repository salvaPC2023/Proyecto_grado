from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

from src.modulos.acceso_roles.dominio.puertos import RepositorioTecnicos
from src.modulos.ubicaciones_tecnicas.dominio.puertos import RepositorioUbicacionesTecnicas

from ..dominio.modelos import PASOS_SEGURIDAD, ClaveControl, OrdenDeTrabajo, PasoOT, TipoOrden
from ..dominio.puertos import RepositorioOrdenesTrabajo


class PrioridadInvalida(Exception):
    pass


class FechasInvalidas(Exception):
    pass


class SinPasoPM01(Exception):
    pass


class HorasInvalidas(Exception):
    pass


class UbicacionNoEncontrada(Exception):
    pass


class TecnicoFueraDeGrupo(Exception):
    pass


@dataclass
class PasoSolicitado:
    descripcion: str
    clave_control: ClaveControl
    horas_planificadas: Decimal | None = None


def validar_pasos(pasos: list[PasoSolicitado]) -> None:
    if not any(p.clave_control == "PM01" for p in pasos):
        raise SinPasoPM01()

    for paso in pasos:
        if paso.clave_control == "PM01" and (
            paso.horas_planificadas is None or paso.horas_planificadas <= 0
        ):
            raise HorasInvalidas("Los pasos PM01 requieren horas planificadas mayores a 0")
        if paso.clave_control == "PMNN" and paso.horas_planificadas is not None:
            raise HorasInvalidas("Los pasos PMNN no llevan horas planificadas")


def crear_ot(
    titulo: str,
    tipo_de_orden: TipoOrden,
    ubicacion_tecnica_id: UUID,
    tecnico_asignado_id: UUID,
    descripcion: str,
    prioridad: int,
    estatus_equipo: bool,
    fecha_inic_planif: datetime,
    fecha_fin_planif: datetime,
    pasos: list[PasoSolicitado],
    supervisor_usuario_id: UUID,
    repositorio_ots: RepositorioOrdenesTrabajo,
    repositorio_ubicaciones: RepositorioUbicacionesTecnicas,
    repositorio_tecnicos: RepositorioTecnicos,
) -> OrdenDeTrabajo:
    if not 1 <= prioridad <= 4:
        raise PrioridadInvalida()
    if fecha_fin_planif < fecha_inic_planif:
        raise FechasInvalidas()
    validar_pasos(pasos)

    if repositorio_ubicaciones.obtener_por_id(ubicacion_tecnica_id) is None:
        raise UbicacionNoEncontrada()
    if not repositorio_tecnicos.pertenece_a_supervisor(
        tecnico_asignado_id, supervisor_usuario_id
    ):
        raise TecnicoFueraDeGrupo()

    ot_id = uuid4()
    pasos_seguridad = [
        PasoOT(
            id=uuid4(),
            ot_id=ot_id,
            numero_paso=numero,
            descripcion=texto,
            clave_control="PMNN",
        )
        for numero, texto in enumerate(PASOS_SEGURIDAD, start=1)
    ]
    pasos_supervisor = [
        PasoOT(
            id=uuid4(),
            ot_id=ot_id,
            numero_paso=numero,
            descripcion=paso.descripcion,
            clave_control=paso.clave_control,
            horas_planificadas=paso.horas_planificadas,
        )
        for numero, paso in enumerate(pasos, start=len(PASOS_SEGURIDAD) + 1)
    ]

    ot = OrdenDeTrabajo(
        id=ot_id,
        tecnico_asignado_id=tecnico_asignado_id,
        ubicacion_tecnica_id=ubicacion_tecnica_id,
        creado_por_id=supervisor_usuario_id,
        titulo=titulo,
        tipo_de_orden=tipo_de_orden,
        descripcion=descripcion,
        prioridad=prioridad,
        estatus_equipo=estatus_equipo,
        estatus="asignada",
        fecha_inic_planif=fecha_inic_planif,
        fecha_fin_planif=fecha_fin_planif,
        pasos=pasos_seguridad + pasos_supervisor,
    )
    return repositorio_ots.crear(ot)
