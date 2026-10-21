import re

from ..dominio.estructura import cumple_estructura
from ..dominio.mediciones import conserva_mediciones
from ..dominio.puertos import ServicioEstandarizacion, ServicioNoDisponible


class DescripcionVacia(Exception):
    pass


def numeros_de(texto: str) -> list[str]:
    # "1,5" y "1.5" cuentan como el mismo número
    return sorted(n.replace(",", ".") for n in re.findall(r"\d+(?:[.,]\d+)?", texto))


def estandarizar_descripcion(texto: str, servicio: ServicioEstandarizacion) -> str:
    texto = texto.strip()
    if not texto:
        raise DescripcionVacia()

    resultado = servicio.estandarizar(texto).strip()
    # no se acepta un resultado vacío, fuera de la plantilla, que pierda o cambie algún valor numérico,
    # ni que quite o agregue una unidad; la app ofrece entonces continuar con el texto original
    if (
        not resultado
        or not cumple_estructura(resultado)
        or set(numeros_de(resultado)) != set(numeros_de(texto))
        or not conserva_mediciones(texto, resultado)
    ):
        raise ServicioNoDisponible()
    return resultado
