from dataclasses import dataclass, field
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Literal
from uuid import UUID

TipoOrden = Literal["OE01", "OE02", "OE03", "OE04"]
EstatusOT = Literal["asignada", "en_progreso", "cerrada"]
ClaveControl = Literal["PM01", "PMNN"]
ResultadoTrabajo = Literal["ejecutado", "no_ejecutado"]
PASOS_SEGURIDAD = ("Piense de manera inteligente", "Vea, diga, haga algo", "Se tiene habilidades adecuadas para la tarea")

# límites acordados tras las pruebas con usuarios (29/10/2026): evitan valores absurdos
MAX_HORAS_POR_PASO = Decimal("12")  # planificadas por el supervisor o trabajadas por el técnico
MAX_DESCRIPCION_PASO = 500  # descripción de un paso escrita por el supervisor
MAX_DESCRIPCION_CIERRE = 4000  # lo que escribe el técnico, o el texto estandarizado que es algo más largo
# un día después del fin planificado, los PM01 sin cerrar se cierran solos como no ejecutados
PLAZO_DE_CIERRE = timedelta(days=1)
DESCRIPCION_CIERRE_AUTOMATICO = "Cerrado automáticamente: no se registró antes del vencimiento de la OT."


@dataclass
class CierrePaso:
    id: UUID
    paso_ot_id: UUID
    fecha_hora_notificacion: datetime
    tiempo_real_trabajado: Decimal
    trabajo_finalizado: bool
    sin_trabajo_realizado: bool
    resultado_trabajo: ResultadoTrabajo
    descripcion_trabajo_realizado: str


@dataclass
class PasoOT:
    id: UUID
    ot_id: UUID
    numero_paso: int | None  # los pasos de seguridad no llevan número; los del supervisor empiezan en 1
    descripcion: str
    clave_control: ClaveControl
    horas_planificadas: Decimal | None = None
    cierre: CierrePaso | None = None


def orden_de_paso(paso: PasoOT) -> tuple[int, int]:
    """Primero los pasos de seguridad, en el orden de PASOS_SEGURIDAD; después los del supervisor por número"""
    if paso.numero_paso is None:
        return 0, PASOS_SEGURIDAD.index(paso.descripcion) if paso.descripcion in PASOS_SEGURIDAD else len(PASOS_SEGURIDAD)
    return 1, paso.numero_paso


@dataclass
class OrdenDeTrabajo:
    id: UUID
    titulo: str
    tipo_de_orden: TipoOrden
    ubicacion_tecnica_id: UUID
    tecnico_asignado_id: UUID
    creado_por_id: UUID
    prioridad: int
    estatus_equipo: bool
    estatus: EstatusOT
    fecha_inic_planif: datetime
    fecha_fin_planif: datetime
    fecha_cierre: datetime | None = None
    pasos: list[PasoOT] = field(default_factory=list)

    @property
    def vencimiento(self) -> datetime:
        """Desde este momento el técnico ya no puede cerrar pasos: los pendientes se cierran solos"""
        return self.fecha_fin_planif + PLAZO_DE_CIERRE
