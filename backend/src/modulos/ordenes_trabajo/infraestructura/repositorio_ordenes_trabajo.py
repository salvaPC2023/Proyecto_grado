from datetime import date, datetime, time, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from src.modulos.acceso_roles.infraestructura.orm import TecnicoORM

from ..dominio.modelos import OrdenDeTrabajo, PasoOT
from ..dominio.puertos import RepositorioOrdenesTrabajo
from .orm import OrdenDeTrabajoORM, PasoOTORM


def rango_del_dia(fecha: date) -> tuple[datetime, datetime]:
    inicio = datetime.combine(fecha, time.min)
    return inicio, inicio + timedelta(days=1)


def paso_a_dominio(orm: PasoOTORM) -> PasoOT:
    return PasoOT(id=orm.id, ot_id=orm.ot_id, numero_paso=orm.numero_paso, descripcion=orm.descripcion, clave_control=orm.clave_control, horas_planificadas=orm.horas_planificadas)


def ot_a_dominio(orm: OrdenDeTrabajoORM) -> OrdenDeTrabajo:
    return OrdenDeTrabajo(
        id=orm.id,
        titulo=orm.titulo,
        tipo_de_orden=orm.tipo_de_orden,
        ubicacion_tecnica_id=orm.ubicacion_tecnica_id,
        tecnico_asignado_id=orm.tecnico_asignado_id,
        creado_por_id=orm.creado_por_id,
        descripcion=orm.descripcion,
        prioridad=orm.prioridad,
        estatus_equipo=orm.estatus_equipo,
        estatus=orm.estatus,
        fecha_inic_planif=orm.fecha_inic_planif,
        fecha_fin_planif=orm.fecha_fin_planif,
        fecha_cierre=orm.fecha_cierre,
        pasos=[paso_a_dominio(p) for p in orm.pasos],
    )


class RepositorioOrdenesTrabajoSQL(RepositorioOrdenesTrabajo):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def crear(self, ot: OrdenDeTrabajo) -> OrdenDeTrabajo:
        orm = OrdenDeTrabajoORM(
            id=ot.id,
            titulo=ot.titulo,
            tipo_de_orden=ot.tipo_de_orden,
            ubicacion_tecnica_id=ot.ubicacion_tecnica_id,
            creado_por_id=ot.creado_por_id,
            tecnico_asignado_id=ot.tecnico_asignado_id,
            descripcion=ot.descripcion,
            prioridad=ot.prioridad,
            estatus=ot.estatus,
            estatus_equipo=ot.estatus_equipo,
            fecha_inic_planif=ot.fecha_inic_planif,
            fecha_fin_planif=ot.fecha_fin_planif,
            fecha_cierre=ot.fecha_cierre,
            pasos=[
                PasoOTORM(id=p.id, ot_id=p.ot_id, numero_paso=p.numero_paso, descripcion=p.descripcion, clave_control=p.clave_control, horas_planificadas=p.horas_planificadas)
                for p in ot.pasos
            ],
        )
        self._sesion.add(orm)
        self._sesion.commit()
        self._sesion.refresh(orm)
        return ot_a_dominio(orm)

    def obtener_por_id(self, id: UUID) -> OrdenDeTrabajo | None:
        orm = self._sesion.get(OrdenDeTrabajoORM, id)
        return ot_a_dominio(orm) if orm else None

    def listar_por_tecnico(self, tecnico_id: UUID, fecha: date | None = None) -> list[OrdenDeTrabajo]:
        consulta = select(OrdenDeTrabajoORM).where(OrdenDeTrabajoORM.tecnico_asignado_id == tecnico_id)
        return self.ejecutar(consulta, fecha)

    def listar_por_grupo(self, grupo_id: UUID, fecha: date | None = None) -> list[OrdenDeTrabajo]:
        consulta = select(OrdenDeTrabajoORM).join(TecnicoORM, OrdenDeTrabajoORM.tecnico_asignado_id == TecnicoORM.id).where(TecnicoORM.grupo_id == grupo_id)
        return self.ejecutar(consulta, fecha)

    def ejecutar(self, consulta, fecha: date | None) -> list[OrdenDeTrabajo]:
        if fecha is not None:
            inicio_dia, fin_dia = rango_del_dia(fecha)
            consulta = consulta.where(OrdenDeTrabajoORM.fecha_inic_planif < fin_dia, OrdenDeTrabajoORM.fecha_fin_planif >= inicio_dia)
        consulta = consulta.order_by(OrdenDeTrabajoORM.fecha_inic_planif, OrdenDeTrabajoORM.prioridad, OrdenDeTrabajoORM.titulo, OrdenDeTrabajoORM.id)
        return [ot_a_dominio(o) for o in self._sesion.scalars(consulta).all()]
