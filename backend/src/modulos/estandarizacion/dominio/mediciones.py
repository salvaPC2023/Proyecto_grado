import re

# Unidades que se reconocen junto a un número, con su forma normalizada. Las variantes de una misma
# unidad cuentan como iguales ("45C", "45 °C" y "45 grados"), porque el modelo puede corregir la
# escritura. Las letras sueltas (C, V, A) solo cuentan si no siguen más letras ("45 Condensador" no).
_UNIDADES = (
    (r"°\s*C|º\s*C|grados(?:\s+(?:C|centígrados))?|C(?![A-Za-zÁÉÍÓÚáéíóúÑñ])", "°C"),
    (r"[dD][bB](?![A-Za-z])", "dB"),
    (r"mm/s", "mm/s"),
    (r"%", "%"),
    (r"bar(?![A-Za-z])", "bar"),
    (r"psi(?![A-Za-z])", "psi"),
    (r"rpm(?![A-Za-z])", "rpm"),
    (r"Hz(?![A-Za-z])", "Hz"),
    (r"kW(?![A-Za-z])", "kW"),
    (r"V(?![A-Za-z])", "V"),
    (r"A(?![A-Za-z])", "A"),
)
_PATRON = re.compile(r"(\d+(?:[.,]\d+)?)\s*(" + "|".join(f"(?:{p})" for p, _ in _UNIDADES) + r")?")


def _normalizar_unidad(unidad: str) -> str:
    return next(nombre for patron, nombre in _UNIDADES if re.fullmatch(patron, unidad))


def mediciones_de(texto: str) -> set[tuple[str, str | None]]:
    """Cada número con su unidad, si la tiene: {("45", "°C"), ("29", None)}.
    "1,5" y "1.5" cuentan como el mismo número"""
    return {
        (numero.replace(",", "."), _normalizar_unidad(unidad) if unidad else None)
        for numero, unidad in _PATRON.findall(texto)
    }


def conserva_mediciones(original: str, resultado: str) -> bool:
    """True si el resultado tiene los mismos números que el original y cada uno con su misma unidad:
    no se pierde una unidad que el técnico escribió ni se agrega una que no escribió"""
    return mediciones_de(original) == mediciones_de(resultado)
