from datetime import datetime
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from src.compartido.bd import get_db
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, requerir_supervisor
from src.modulos.acceso_roles.infraestructura.repositorio_tecnicos import RepositorioTecnicosSQL
from src.modulos.ubicaciones_tecnicas.infraestructura.repositorio_ubicaciones_tecnicas import RepositorioUbicacionesTecnicasSQL
from src.modulos.ubicaciones_tecnicas.infraestructura.router import UbicacionOut, a_ubicacion_out

from ..aplicacion.crear_ot import FechasInvalidas, HorasInvalidas, PasoSolicitado, PrioridadInvalida, SinPasoPM01, TecnicoFueraDeGrupo, UbicacionNoEncontrada, crear_ot
from ..dominio.modelos import ClaveControl, EstatusOT, OrdenDeTrabajo, TipoOrden
from .repositorio_ordenes_trabajo import RepositorioOrdenesTrabajoSQL

# Rutas y campos coinciden con lo que llama la app movil (repositorio_ordenes_trabajo_remoto.dart y mapeo_json.dart).
router_ots = APIRouter(prefix="/ordenes-trabajo", tags=["ordenes de trabajo"])


class PasoIn(BaseModel):
    descripcion: str = Field(min_length=1)
    clave_control: ClaveControl
    # Igual que la columna DECIMAL(5,2): hasta 999.99. Sin esto, un valor mayor llega a la BD y responde 500.
    horas_planificadas: Decimal | None = Field(default=None, max_digits=5, decimal_places=2, examples=["2.50"])


class CrearOTRequest(BaseModel):
    titulo: str = Field(min_length=1, max_length=150)
    tipo_de_orden: TipoOrden
    ubicacion_tecnica_id: UUID
    tecnico_asignado_id: UUID
    descripcion: str = Field(min_length=1)
    prioridad: int
    estatus_equipo: bool
    fecha_inic_planif: datetime
    fecha_fin_planif: datetime
    pasos: list[PasoIn]

    @field_validator("fecha_inic_planif", "fecha_fin_planif")
    @classmethod
    def sin_zona_horaria(cls, valor: datetime) -> datetime:
        # Las columnas son TIMESTAMP (sin zona) y el sistema opera en hora de Bolivia.
        # Si la fecha llega con zona ("Z", "-04:00"), se pasa a la hora local del servidor.
        if valor.tzinfo is not None:
            return valor.astimezone().replace(tzinfo=None)
        return valor


class PasoOut(BaseModel):
    id: UUID
    numero_paso: int
    descripcion: str
    clave_control: ClaveControl
    horas_planificadas: Decimal | None = Field(examples=["2.50"])
    cierre: None = None  # El cierre de paso llega en el Bloque G.


class OrdenDeTrabajoOut(BaseModel):
    id: UUID
    titulo: str
    tipo_de_orden: TipoOrden
    ubicacion_tecnica_id: UUID
    tecnico_asignado_id: UUID
    creado_por_id: UUID
    descripcion: str
    prioridad: int
    estatus: EstatusOT
    estatus_equipo: bool
    fecha_inic_planif: datetime
    fecha_fin_planif: datetime
    fecha_cierre: datetime | None
    ubicacion: UbicacionOut | None
    pasos: list[PasoOut]


def a_ot_out(ot: OrdenDeTrabajo, ubicacion) -> OrdenDeTrabajoOut:
    return OrdenDeTrabajoOut(
        id=ot.id,
        titulo=ot.titulo,
        tipo_de_orden=ot.tipo_de_orden,
        ubicacion_tecnica_id=ot.ubicacion_tecnica_id,
        tecnico_asignado_id=ot.tecnico_asignado_id,
        creado_por_id=ot.creado_por_id,
        descripcion=ot.descripcion,
        prioridad=ot.prioridad,
        estatus=ot.estatus,
        estatus_equipo=ot.estatus_equipo,
        fecha_inic_planif=ot.fecha_inic_planif,
        fecha_fin_planif=ot.fecha_fin_planif,
        fecha_cierre=ot.fecha_cierre,
        ubicacion=a_ubicacion_out(ubicacion) if ubicacion else None,
        pasos=[PasoOut(id=p.id, numero_paso=p.numero_paso, descripcion=p.descripcion, clave_control=p.clave_control, horas_planificadas=p.horas_planificadas) for p in ot.pasos],
    )


@router_ots.post("", response_model=OrdenDeTrabajoOut, status_code=status.HTTP_201_CREATED)
def crear_ot_endpoint(datos: CrearOTRequest, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_supervisor)):
    repositorio_ubicaciones = RepositorioUbicacionesTecnicasSQL(db)
    try:
        ot = crear_ot(
            titulo=datos.titulo,
            tipo_de_orden=datos.tipo_de_orden,
            ubicacion_tecnica_id=datos.ubicacion_tecnica_id,
            tecnico_asignado_id=datos.tecnico_asignado_id,
            descripcion=datos.descripcion,
            prioridad=datos.prioridad,
            estatus_equipo=datos.estatus_equipo,
            fecha_inic_planif=datos.fecha_inic_planif,
            fecha_fin_planif=datos.fecha_fin_planif,
            pasos=[PasoSolicitado(descripcion=p.descripcion, clave_control=p.clave_control, horas_planificadas=p.horas_planificadas) for p in datos.pasos],
            supervisor_usuario_id=actual.id,
            repositorio_ots=RepositorioOrdenesTrabajoSQL(db),
            repositorio_ubicaciones=repositorio_ubicaciones,
            repositorio_tecnicos=RepositorioTecnicosSQL(db),
        )
    except PrioridadInvalida:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="La prioridad debe estar entre 1 y 4")
    except FechasInvalidas:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="La fecha de fin no puede ser anterior a la de inicio")
    except SinPasoPM01:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="Se requiere al menos un paso PM01")
    except HorasInvalidas as error:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(error))
    except UbicacionNoEncontrada:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ubicación técnica no encontrada")
    except TecnicoFueraDeGrupo:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El técnico no existe o no pertenece a tu grupo")
    return a_ot_out(ot, repositorio_ubicaciones.obtener_por_id(ot.ubicacion_tecnica_id))
