from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from src.compartido.bd import get_db
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual, requerir_supervisor, requerir_tecnico
from src.modulos.acceso_roles.infraestructura.repositorio_supervisores import RepositorioSupervisoresSQL
from src.modulos.acceso_roles.infraestructura.repositorio_tecnicos import RepositorioTecnicosSQL
from src.modulos.ubicaciones_tecnicas.infraestructura.repositorio_ubicaciones_tecnicas import RepositorioUbicacionesTecnicasSQL
from src.modulos.ubicaciones_tecnicas.infraestructura.router import UbicacionOut, a_ubicacion_out

from ..aplicacion.crear_ot import FechasInvalidas, HorasInvalidas, PasoSolicitado, PrioridadInvalida, SinPasoPM01, SupervisorNoEncontrado, TecnicoFueraDeGrupo, UbicacionNoEncontrada, crear_ot
from ..aplicacion.listar_ots_supervisor import listar_ots_supervisor
from ..aplicacion.listar_ots_tecnico import listar_ots_tecnico
from ..aplicacion.registrar_cierre_paso import CierreAnticipado, DescripcionVacia, OTYaCerrada, PasoNoEncontrado, PasoNoRegistrable, PasoYaCerrado, TiempoInvalido, registrar_cierre_paso
from ..aplicacion.ver_detalle_ot import OTNoEncontrada, SinAccesoAOT, ver_detalle_ot
from ..dominio.modelos import CierrePaso, ClaveControl, EstatusOT, OrdenDeTrabajo, ResultadoTrabajo, TipoOrden
from .repositorio_ordenes_trabajo import RepositorioOrdenesTrabajoSQL

router_ots = APIRouter(prefix="/ordenes-trabajo", tags=["ordenes de trabajo"])


class PasoIn(BaseModel):
    descripcion: str = Field(min_length=1)
    clave_control: ClaveControl
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
        if valor.tzinfo is not None:
            return valor.astimezone().replace(tzinfo=None)
        return valor


class CierreIn(BaseModel):
    resultado_trabajo: ResultadoTrabajo
    tiempo_real_trabajado: Decimal = Field(ge=0, max_digits=5, decimal_places=2, examples=["1.50"])
    descripcion_trabajo_realizado: str = Field(min_length=1)


class CierreOut(BaseModel):
    id: UUID
    fecha_hora_notificacion: datetime
    tiempo_real_trabajado: Decimal = Field(examples=["1.50"])
    trabajo_finalizado: bool
    sin_trabajo_realizado: bool
    resultado_trabajo: ResultadoTrabajo
    descripcion_trabajo_realizado: str


def a_cierre_out(cierre: CierrePaso | None) -> CierreOut | None:
    if cierre is None:
        return None
    return CierreOut(
        id=cierre.id,
        fecha_hora_notificacion=cierre.fecha_hora_notificacion,
        tiempo_real_trabajado=cierre.tiempo_real_trabajado,
        trabajo_finalizado=cierre.trabajo_finalizado,
        sin_trabajo_realizado=cierre.sin_trabajo_realizado,
        resultado_trabajo=cierre.resultado_trabajo,
        descripcion_trabajo_realizado=cierre.descripcion_trabajo_realizado,
    )


class PasoOut(BaseModel):
    id: UUID
    numero_paso: int
    descripcion: str
    clave_control: ClaveControl
    horas_planificadas: Decimal | None = Field(examples=["2.50"])
    cierre: CierreOut | None = None


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
        pasos=[PasoOut(id=p.id, numero_paso=p.numero_paso, descripcion=p.descripcion, clave_control=p.clave_control, horas_planificadas=p.horas_planificadas, cierre=a_cierre_out(p.cierre)) for p in ot.pasos],
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
            repositorio_supervisores=RepositorioSupervisoresSQL(db),
        )
    except SupervisorNoEncontrado:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo un supervisor registrado puede crear órdenes de trabajo")
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


def a_lista_out(ots: list[OrdenDeTrabajo], repositorio_ubicaciones: RepositorioUbicacionesTecnicasSQL) -> list[OrdenDeTrabajoOut]:
    ubicaciones = {u.id: u for u in repositorio_ubicaciones.listar_ubicaciones()}
    return [a_ot_out(ot, ubicaciones.get(ot.ubicacion_tecnica_id)) for ot in ots]


@router_ots.get("/mis-ots", response_model=list[OrdenDeTrabajoOut])
def listar_mis_ots_endpoint(fecha: date | None = None, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_tecnico)):
    ots = listar_ots_tecnico(actual.id, RepositorioOrdenesTrabajoSQL(db), RepositorioTecnicosSQL(db), fecha)
    return a_lista_out(ots, RepositorioUbicacionesTecnicasSQL(db))


@router_ots.get("/grupo", response_model=list[OrdenDeTrabajoOut])
def listar_ots_grupo_endpoint(fecha: date | None = None, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_supervisor)):
    ots = listar_ots_supervisor(actual.id, RepositorioOrdenesTrabajoSQL(db), RepositorioTecnicosSQL(db), fecha)
    return a_lista_out(ots, RepositorioUbicacionesTecnicasSQL(db))


@router_ots.get("/{ot_id}", response_model=OrdenDeTrabajoOut)
def ver_detalle_ot_endpoint(ot_id: UUID, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(obtener_usuario_actual)):
    try:
        ot = ver_detalle_ot(ot_id, actual.id, actual.rol, RepositorioOrdenesTrabajoSQL(db), RepositorioTecnicosSQL(db))
    except OTNoEncontrada:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Orden de trabajo no encontrada")
    except SinAccesoAOT:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta orden de trabajo")
    return a_ot_out(ot, RepositorioUbicacionesTecnicasSQL(db).obtener_por_id(ot.ubicacion_tecnica_id))


@router_ots.post("/{ot_id}/pasos/{paso_id}/cierre", response_model=OrdenDeTrabajoOut, status_code=status.HTTP_201_CREATED)
def registrar_cierre_endpoint(ot_id: UUID, paso_id: UUID, datos: CierreIn, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_tecnico)):
    try:
        ot = registrar_cierre_paso(
            ot_id=ot_id,
            paso_id=paso_id,
            tecnico_usuario_id=actual.id,
            resultado_trabajo=datos.resultado_trabajo,
            tiempo_real_trabajado=datos.tiempo_real_trabajado,
            descripcion_trabajo_realizado=datos.descripcion_trabajo_realizado,
            repositorio_ots=RepositorioOrdenesTrabajoSQL(db),
            repositorio_tecnicos=RepositorioTecnicosSQL(db),
        )
    except OTNoEncontrada:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Orden de trabajo no encontrada")
    except PasoNoEncontrado:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="El paso no pertenece a esta orden de trabajo")
    except SinAccesoAOT:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta orden de trabajo")
    except OTYaCerrada:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="La orden de trabajo ya está cerrada")
    except PasoYaCerrado:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="El paso ya tiene un cierre registrado")
    except PasoNoRegistrable:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="Solo los pasos PM01 se cierran")
    except TiempoInvalido:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="Si el trabajo se ejecutó, el tiempo debe ser mayor a 0; si no se ejecutó, debe ser 0")
    except DescripcionVacia:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="Describe el trabajo realizado")
    except CierreAnticipado:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="No se puede cerrar un paso antes del día de inicio planificado")
    return a_ot_out(ot, RepositorioUbicacionesTecnicasSQL(db).obtener_por_id(ot.ubicacion_tecnica_id))
