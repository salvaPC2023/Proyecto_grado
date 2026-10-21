# Secciones de la plantilla de salida, en su orden. El prompt de sistema usa los mismos títulos
# (un test comprueba que coincidan); cada sección es opcional porque el modelo omite las vacías.
SECCIONES = (
    "Equipo intervenido:",
    "Actividades realizadas:",
    "Mediciones termográficas:",
    "Mediciones de vibración:",
    "Observaciones:",
)

_MARCAS_MARKDOWN = ("**", "```", "#")


def _seccion_de(linea: str) -> int | None:
    """Posición de la sección con la que empieza la línea, o None si no es un título"""
    return next((i for i, titulo in enumerate(SECCIONES) if linea.startswith(titulo)), None)


def cumple_estructura(texto: str) -> bool:
    """True si el texto sigue la plantilla: al menos una sección, en orden, sin repetir, sin texto
    antes de la primera y en texto plano"""
    lineas = [linea.strip() for linea in texto.splitlines() if linea.strip()]
    if not lineas or any(linea.startswith(_MARCAS_MARKDOWN) or "**" in linea for linea in lineas):
        return False
    # nada antes de la primera sección: descarta respuestas como "Claro, aquí tienes:"
    if _seccion_de(lineas[0]) is None:
        return False

    anterior = -1
    for linea in lineas:
        actual = _seccion_de(linea)
        if actual is None:
            # un título que no es de la plantilla, como "Mediciones de temperatura:", no se acepta
            # como contenido de la sección anterior
            if not linea.startswith("-") and linea.endswith(":"):
                return False
            continue  # contenido de la sección en curso, por ejemplo "- Se cambió el rodamiento"
        if actual <= anterior:  # fuera de orden o repetida
            return False
        anterior = actual
    return True
