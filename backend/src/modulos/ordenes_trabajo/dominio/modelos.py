from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

TipoOrden = Literal["OE01", "OE02", "OE03", "OE04"]
EstatusOT = Literal["asignada", "en_progreso", "cerrada"]
ClaveControl = Literal["PM01", "PMNN"]
PASOS_SEGURIDAD = ("Piense de manera inteligente", "Vea, diga, haga algo", "Se tiene habilidades adecuadas para la tarea")


@dataclass
class PasoOT:
    id: UUID
    ot_id: UUID
    numero_paso: int
    descripcion: str
    clave_control: ClaveControl
    horas_planificadas: Decimal | None = None


@dataclass
class OrdenDeTrabajo:
    id: UUID
    titulo: str
    tipo_de_orden: TipoOrden
    ubicacion_tecnica_id: UUID
    tecnico_asignado_id: UUID
    creado_por_id: UUID
    descripcion: str
    prioridad: int
    estatus_equipo: bool
    estatus: EstatusOT
    fecha_inic_planif: datetime
    fecha_fin_planif: datetime
    fecha_cierre: datetime | None = None
    pasos: list[PasoOT] = field(default_factory=list)
