import pytest

from src.modulos.estandarizacion.aplicacion.estandarizar_descripcion import DescripcionVacia, estandarizar_descripcion
from src.modulos.estandarizacion.dominio.estructura import SECCIONES, cumple_estructura
from src.modulos.estandarizacion.dominio.puertos import ServicioEstandarizacion, ServicioNoDisponible
from src.modulos.estandarizacion.infraestructura.prompt_sistema import PROMPT_SISTEMA

# La respuesta de OpenAI no es determinista, así que no se prueba: se reemplaza por un servicio
# falso y se prueban las reglas que el sistema aplica a cualquier respuesta del modelo.


class ServicioFalso(ServicioEstandarizacion):
    """Reemplaza a OpenAI: devuelve siempre la respuesta indicada"""

    def __init__(self, respuesta: str):
        self.respuesta = respuesta
        self.llamadas = 0

    def estandarizar(self, texto: str) -> str:
        self.llamadas += 1
        return self.respuesta


ORIGINAL = "cambie el rodamiento del motor de la llenadora, temperatura 85 C, vibracion 4,5 mm/s"

RESPUESTA_CORRECTA = """Equipo intervenido: Motor de la llenadora

Actividades realizadas:
- Se cambió el rodamiento

Mediciones termográficas:
- Motor: 85 °C

Mediciones de vibración:
- Motor: 4.5 mm/s"""


def test_respuesta_con_la_estructura_de_la_plantilla_se_acepta():
    resultado = estandarizar_descripcion(ORIGINAL, ServicioFalso(RESPUESTA_CORRECTA))

    assert resultado == RESPUESTA_CORRECTA


def test_respuesta_sin_la_estructura_de_la_plantilla_se_rechaza():
    sin_estructura = "Se cambió el rodamiento del motor de la llenadora. Temperatura 85 °C y vibración 4.5 mm/s."

    with pytest.raises(ServicioNoDisponible):
        estandarizar_descripcion(ORIGINAL, ServicioFalso(sin_estructura))


def test_respuesta_que_pierde_un_valor_numerico_se_rechaza():
    sin_la_vibracion = RESPUESTA_CORRECTA.replace("\n\nMediciones de vibración:\n- Motor: 4.5 mm/s", "")

    with pytest.raises(ServicioNoDisponible):
        estandarizar_descripcion(ORIGINAL, ServicioFalso(sin_la_vibracion))


def test_respuesta_que_cambia_un_valor_numerico_se_rechaza():
    with pytest.raises(ServicioNoDisponible):
        estandarizar_descripcion(ORIGINAL, ServicioFalso(RESPUESTA_CORRECTA.replace("85", "58")))


def test_coma_y_punto_decimal_cuentan_como_el_mismo_numero():
    # el técnico escribió "4,5" y el modelo devolvió "4.5"
    assert estandarizar_descripcion(ORIGINAL, ServicioFalso(RESPUESTA_CORRECTA)) == RESPUESTA_CORRECTA


def test_respuesta_vacia_se_rechaza():
    with pytest.raises(ServicioNoDisponible):
        estandarizar_descripcion(ORIGINAL, ServicioFalso("   "))


def test_texto_vacio_no_llama_al_modelo():
    servicio = ServicioFalso(RESPUESTA_CORRECTA)

    with pytest.raises(DescripcionVacia):
        estandarizar_descripcion("   ", servicio)

    assert servicio.llamadas == 0


# --- reglas de la estructura ---

def test_basta_una_seccion_porque_el_modelo_omite_las_vacias():
    assert cumple_estructura("Observaciones: No había repuesto")


def test_secciones_fuera_de_orden_no_cumplen():
    assert not cumple_estructura("Observaciones: Sin novedades\n\nEquipo intervenido: Motor")


def test_seccion_repetida_no_cumple():
    assert not cumple_estructura("Actividades realizadas:\n- Se limpió\n\nActividades realizadas:\n- Se ajustó")


def test_texto_antes_de_la_primera_seccion_no_cumple():
    assert not cumple_estructura("Claro, aquí tienes el texto:\n\nEquipo intervenido: Motor")


def test_una_seccion_que_no_es_de_la_plantilla_no_cumple():
    # caso real de la evaluación del 21/10 (prueba 11): el modelo inventó esta sección
    inventada = "Mediciones de vibración:\n- Lado del motor: 35\n\nMediciones de temperatura:\n- Entrada: 34"

    assert not cumple_estructura(inventada)


def test_markdown_no_cumple():
    assert not cumple_estructura("**Equipo intervenido:** Motor")


def test_el_prompt_usa_los_mismos_titulos_que_la_validacion():
    # si alguien cambia un título en el prompt, la validación rechazaría todas las respuestas
    for titulo in SECCIONES:
        assert titulo in PROMPT_SISTEMA
