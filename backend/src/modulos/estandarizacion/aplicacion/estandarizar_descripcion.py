import logging
import re

from src.modulos.ordenes_trabajo.dominio.modelos import MAX_DESCRIPCION_CIERRE

from ..dominio.estructura import cumple_estructura
from ..dominio.mediciones import conserva_mediciones, quitar_unidades_agregadas
from ..dominio.puertos import ServicioEstandarizacion, ServicioNoDisponible

registro = logging.getLogger("uvicorn.error")


class DescripcionVacia(Exception):
    pass


def numeros_de(texto: str) -> list[str]:
    # "1,5" y "1.5" cuentan como el mismo número
    return sorted(n.replace(",", ".") for n in re.findall(r"\d+(?:[.,]\d+)?", texto))


def estandarizar_descripcion(texto: str, servicio: ServicioEstandarizacion) -> str:
    texto = texto.strip()
    if not texto:
        raise DescripcionVacia()

    # si el modelo agregó una unidad que el técnico no escribió, se le quita antes de validar
    resultado = quitar_unidades_agregadas(texto, servicio.estandarizar(texto).strip())
    # no se acepta un resultado vacío, fuera de la plantilla, que pierda o cambie algún valor numérico,
    # ni que quite o agregue una unidad; la app ofrece entonces continuar con el texto original
    motivo = motivo_de_rechazo(texto, resultado)
    if motivo:
        # queda en la terminal del backend para saber por qué falló (las pruebas con usuarios lo necesitan)
        registro.warning("Estandarización rechazada: %s", motivo)
        raise ServicioNoDisponible()
    return resultado


def motivo_de_rechazo(texto: str, resultado: str) -> str | None:
    """Por qué no se acepta la respuesta del modelo, o None si se acepta"""
    if not resultado:
        return "respuesta vacía"
    if len(resultado) > MAX_DESCRIPCION_CIERRE:
        return f"la respuesta pasa de {MAX_DESCRIPCION_CIERRE} caracteres"
    if not cumple_estructura(resultado):
        return "la respuesta no sigue la plantilla (Equipo intervenido, Actividades realizadas, Observaciones)"
    originales, nuevos = set(numeros_de(texto)), set(numeros_de(resultado))
    if originales != nuevos:
        return f"cambiaron los números: faltan {sorted(originales - nuevos)}, sobran {sorted(nuevos - originales)}"
    if not conserva_mediciones(texto, resultado):
        return "se quitó o agregó una unidad de medida"
    return None
