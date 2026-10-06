import re

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
    # no se acepta un resultado vacío ni uno que pierda o cambie algún valor numérico
    if not resultado or set(numeros_de(resultado)) != set(numeros_de(texto)):
        raise ServicioNoDisponible()
    return resultado
