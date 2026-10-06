from io import BytesIO
from uuid import UUID

from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

from src.modulos.ubicaciones_tecnicas.dominio.modelos import UbicacionTecnica

from ..dominio.modelos import OrdenDeTrabajo

# BORRADOR: falta confirmar con el supervisor las columnas que pide SAP
COLUMNAS = [
    ("Título OT", 35), ("Tipo de orden", 13), ("Prioridad", 10), ("Estado OT", 13), ("Equipo en marcha", 16),
    ("Ubicación técnica", 45), ("Técnico", 25), ("Inicio planificado", 18), ("Fin planificado", 18), ("Fecha de cierre OT", 18),
    ("N.º paso", 9), ("Descripción del paso", 40), ("Horas planificadas", 18),
    ("Resultado", 14), ("Tiempo real (h)", 15), ("Fecha de notificación", 20), ("Trabajo finalizado", 17), ("Descripción del trabajo realizado", 60),
]
FORMATO_FECHA = "dd/mm/yyyy hh:mm"
ESTADOS = {"asignada": "Asignada", "en_progreso": "En progreso", "cerrada": "Cerrada"}
RESULTADOS = {"ejecutado": "Ejecutado", "no_ejecutado": "No ejecutado"}


def _ruta(ubicacion: UbicacionTecnica | None) -> str:
    if ubicacion is None:
        return ""
    return " / ".join(n for n in (ubicacion.sector, ubicacion.subsector, ubicacion.sistema, ubicacion.subsistema) if n)


def generar_excel(ots: list[OrdenDeTrabajo], ubicaciones: dict[UUID, UbicacionTecnica], tecnicos: dict[UUID, str]) -> bytes:
    """Una fila por cada paso PM01; los pasos de seguridad (PMNN) no se exportan"""
    libro = Workbook()
    hoja = libro.active
    hoja.title = "Ordenes de trabajo"
    hoja.append([nombre for nombre, _ in COLUMNAS])

    for ot in ots:
        for paso in (p for p in ot.pasos if p.clave_control == "PM01"):
            cierre = paso.cierre
            hoja.append([
                ot.titulo, ot.tipo_de_orden, ot.prioridad, ESTADOS.get(ot.estatus, ot.estatus), "Sí" if ot.estatus_equipo else "No",
                _ruta(ubicaciones.get(ot.ubicacion_tecnica_id)), tecnicos.get(ot.tecnico_asignado_id, ""),
                ot.fecha_inic_planif, ot.fecha_fin_planif, ot.fecha_cierre,
                paso.numero_paso, paso.descripcion, float(paso.horas_planificadas or 0),
                RESULTADOS.get(cierre.resultado_trabajo) if cierre else "Pendiente",
                float(cierre.tiempo_real_trabajado) if cierre else None,
                cierre.fecha_hora_notificacion if cierre else None,
                ("Sí" if cierre.trabajo_finalizado else "No") if cierre else None,
                cierre.descripcion_trabajo_realizado if cierre else None,
            ])

    # encabezado resaltado y fijo, anchos de columna y formato de fechas
    for celda in hoja[1]:
        celda.font = Font(bold=True, color="FFFFFF")
        celda.fill = PatternFill("solid", fgColor="131D8C")
    hoja.freeze_panes = "A2"
    for i, (_, ancho) in enumerate(COLUMNAS, start=1):
        hoja.column_dimensions[hoja.cell(1, i).column_letter].width = ancho
    for fila in hoja.iter_rows(min_row=2):
        for celda in (fila[7], fila[8], fila[9], fila[15]):
            celda.number_format = FORMATO_FECHA

    archivo = BytesIO()
    libro.save(archivo)
    return archivo.getvalue()
