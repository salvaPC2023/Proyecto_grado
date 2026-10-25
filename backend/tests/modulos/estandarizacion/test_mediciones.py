import pytest

from src.modulos.estandarizacion.dominio.mediciones import conserva_mediciones, mediciones_de, quitar_unidades_agregadas

# Casos tomados de las evaluaciones del prompt del 21/10/2026


@pytest.mark.parametrize("original, resultado", [
    ("estator 48°C", "Estator: 48 °C"),
    ("cables a 30 grados", "Cables: 30 °C"),  # misma unidad escrita de otra forma
    ("temp estator 45C", "Estator: 45 °C"),
    ("vibr acople 28db", "Lado acople: 28 dB"),
    ("vibracion 4,5 mm/s", "Vibración: 4.5 mm/s"),  # coma y punto decimal
    ("agua entrada 35", "Agua entrada: 35"),  # sin unidad en los dos
    ("torre TE-01", "Equipo intervenido: torre TE-01"),
])
def test_se_aceptan_las_mediciones_que_conservan_su_unidad(original, resultado):
    assert conserva_mediciones(original, resultado)


def test_perder_una_unidad_que_el_tecnico_escribio_se_rechaza():
    # versión 6246c78e, prueba 15: "78 °C" quedó como "78"
    assert not conserva_mediciones("estator del motor 78 °C", "Estator del motor: 78")


def test_agregar_una_unidad_que_el_tecnico_no_escribio_se_rechaza():
    # versión eb897eed, prueba 9: inventó "mm/s" y "°C"
    assert not conserva_mediciones("vibraciones lado acople 28", "Lado acople: 28 mm/s")
    assert not conserva_mediciones("temperatura del estator 46", "Estator: 46 °C")


def test_cambiar_la_unidad_se_rechaza():
    assert not conserva_mediciones("vibración 28 dB", "Vibración: 28 mm/s")


def test_una_palabra_que_empieza_con_la_letra_de_una_unidad_no_es_unidad():
    # "C" de Celsius no se confunde con la C de "Condensador"
    assert mediciones_de("equipo 01 Condensador") == {("01", None)}


def test_quita_la_unidad_que_el_modelo_agrego_a_un_numero_que_no_la_tenia():
    # prueba con usuarios del 23/10/2026: el técnico escribió "agua entrada 35 y salida 29" sin unidad
    original = "temperatura del estator 45 grados agua entrada 35 y salida 29"
    resultado = "Mediciones termográficas:\n- Estator: 45 °C\n- Agua entrada: 35 °C\n- Agua salida: 29 °C"

    corregido = quitar_unidades_agregadas(original, resultado)

    assert corregido == "Mediciones termográficas:\n- Estator: 45 °C\n- Agua entrada: 35\n- Agua salida: 29"
    assert conserva_mediciones(original, corregido)


def test_no_quita_ni_corrige_una_unidad_que_el_tecnico_si_escribio():
    # si el modelo cambió la unidad, se deja así para que la validación lo rechace
    assert quitar_unidades_agregadas("vibración 28 dB", "Vibración: 28 mm/s") == "Vibración: 28 mm/s"
    assert quitar_unidades_agregadas("estator 45 °C", "Estator: 45 °C") == "Estator: 45 °C"


def test_no_confunde_un_codigo_de_equipo_con_una_medicion():
    assert quitar_unidades_agregadas("torre TE01 agua 35", "Equipo intervenido: Torre TE01\n- Agua: 35 °C") == (
        "Equipo intervenido: Torre TE01\n- Agua: 35"
    )


def test_lee_cada_numero_con_su_unidad():
    assert mediciones_de("estator 45 °C, cables 30 grados, acople 28db, agua 35") == {
        ("45", "°C"), ("30", "°C"), ("28", "dB"), ("35", None),
    }
