from datetime import datetime
from decimal import Decimal
from io import BytesIO

import pytest
from openpyxl import Workbook

from src.modulos.importacion.dominio.reglas import fecha_de, niveles_de_ubicacion, numero_de, si_o_no
from src.modulos.importacion.infraestructura.lector_excel import ENCABEZADOS_OTS, leer_ots, leer_plantilla

# Tabla de órdenes de trabajo de la plantilla: una fila por paso; las filas con el mismo número de OT
# forman una sola orden. Pedido del supervisor en la prueba con usuarios del 23/10/2026.

ENCABEZADOS = ["OT", "Título", "Tipo", "Ubicación Técnica", "Técnico", "Prioridad", "Inicio", "Fin",
               "Equipo en Funcionamiento", "Clave", "Descripción del Paso", "Horas"]


def _libro_con_ots(filas, encabezados=ENCABEZADOS) -> bytes:
    libro = Workbook()
    hoja = libro.active
    hoja.title = "Ordenes de trabajo"
    hoja.append(encabezados)
    for fila in filas:
        hoja.append(fila)
    archivo = BytesIO()
    libro.save(archivo)
    return archivo.getvalue()


def test_los_encabezados_de_la_plantilla_coinciden_con_los_del_lector():
    from src.modulos.importacion.dominio.reglas import normalizar

    assert [normalizar(e) for e in ENCABEZADOS] == ENCABEZADOS_OTS


def test_lee_una_fila_por_paso_con_su_numero_de_fila():
    contenido = _libro_con_ots([
        [1, "Cambio de rodamientos", "OE01", "Embotellado / Area 1 / Llenadora", "Carlos Mamani Quispe", 1,
         datetime(2026, 10, 27, 8), datetime(2026, 10, 27, 12), "No", "PM01", "Desmontar motor", 1.5],
        [1, None, None, None, None, None, None, None, None, "PM01", "Montar rodamientos", 2],
    ])

    filas = leer_ots(contenido)

    assert [f.fila for f in filas] == [2, 3]
    assert filas[0].ot == "1" and filas[1].ot == "1"
    assert filas[0].inicio == "2026-10-27 08:00:00"  # la celda con fecha de Excel
    assert filas[1].descripcion_paso == "Montar rodamientos"


def test_una_plantilla_sin_tabla_de_ots_no_es_un_error():
    libro = Workbook()
    archivo = BytesIO()
    libro.save(archivo)

    assert leer_ots(archivo.getvalue()) == []


def test_la_tabla_de_ots_no_se_confunde_con_las_demas_tablas():
    contenido = _libro_con_ots([[1, "Revisión", "OE02", "Embotellado", "Carlos Mamani", 2, "27/10/2026 08:00",
                                 "27/10/2026 10:00", "Sí", "PM01", "Termografía", 1]])

    personal, ubicaciones, grupos = leer_plantilla(contenido)

    assert (personal, ubicaciones, grupos) == ([], [], [])


def test_encabezados_de_ots_incorrectos_rechazan_el_archivo():
    from src.modulos.importacion.dominio.puertos import PlantillaInvalida

    with pytest.raises(PlantillaInvalida):
        leer_ots(_libro_con_ots([], encabezados=["OT", "Nombre", "Tipo"]))


@pytest.mark.parametrize("texto, esperado", [
    ("2026-10-27 08:00:00", datetime(2026, 10, 27, 8)),
    ("27/10/2026 08:30", datetime(2026, 10, 27, 8, 30)),
    ("27/10/2026", datetime(2026, 10, 27)),
    ("mañana", None),
])
def test_fechas_aceptadas(texto, esperado):
    assert fecha_de(texto) == esperado


@pytest.mark.parametrize("texto, esperado", [("Sí", True), ("si", True), ("NO", False), ("tal vez", None)])
def test_si_o_no(texto, esperado):
    assert si_o_no(texto) is esperado


@pytest.mark.parametrize("texto, esperado", [("1,5", Decimal("1.5")), ("2", Decimal("2")), ("", None), ("dos", None)])
def test_numeros_con_coma_o_punto(texto, esperado):
    assert numero_de(texto) == esperado


def test_la_ubicacion_se_compara_sin_tildes_ni_mayusculas():
    assert niveles_de_ubicacion("Embotellado / Área 1 /Llenadora") == niveles_de_ubicacion("embotellado/area 1/ LLENADORA")
