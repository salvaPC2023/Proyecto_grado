from uuid import UUID

from sqlalchemy.orm import Session

from ..dominio.modelos import OrdenDeTrabajo, PasoOT
from ..dominio.puertos import RepositorioOrdenesTrabajo
from .orm import OrdenDeTrabajoORM, PasoOTORM


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
        # Un solo commit: la OT y todos sus pasos se guardan juntos o no se guarda nada.
        self._sesion.commit()
        self._sesion.refresh(orm)
        return ot_a_dominio(orm)

    def obtener_por_id(self, id: UUID) -> OrdenDeTrabajo | None:
        orm = self._sesion.get(OrdenDeTrabajoORM, id)
        return ot_a_dominio(orm) if orm else None
