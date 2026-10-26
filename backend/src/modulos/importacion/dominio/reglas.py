import re
import unicodedata
from datetime import datetime, time
from decimal import Decimal, InvalidOperation

from src.modulos.acceso_roles.dominio.modelos import Profesion

# "Grupo Planificador" de SAP -> profesión del sistema; electrónico se registra como electromecánico
PROFESIONES: dict[str, Profesion] = {
    "mecanico": "mecanico",
    "electrico": "electrico",
    "electromecanico": "electromecanico",
    "electronico": "electromecanico",
}

# los mismos turnos que la app ofrece al registrar un supervisor
TURNOS: dict[int, tuple[time, time]] = {
    1: (time(23), time(7)),
    2: (time(7), time(15)),
    3: (time(15), time(23)),
}


def normalizar(texto: str) -> str:
    """Minúsculas, sin tildes y con un solo espacio entre palabras, para comparar"""
    sin_tildes = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()
    return " ".join(sin_tildes.lower().split())


def profesion_de(grupo_planificador: str) -> Profesion | None:
    return PROFESIONES.get(normalizar(grupo_planificador))


def separar_nombre(nombre_completo: str) -> tuple[str, str, str | None] | None:
    """Siempre 1 nombre + 2 apellidos; con 2 palabras, 1 nombre + 1 apellido; con 4 o más, las dos últimas son los apellidos"""
    palabras = nombre_completo.split()
    if len(palabras) < 2:
        return None
    if len(palabras) == 2:
        return palabras[0], palabras[1], None
    if len(palabras) == 3:
        return palabras[0], palabras[1], palabras[2]
    return " ".join(palabras[:-2]), palabras[-2], palabras[-1]


def horario_de_turno(turno: str) -> tuple[time, time] | None:
    """Acepta "Turno 1", "turno 2" o solo "3"; None si no es un turno conocido"""
    numero = re.search(r"\d+", turno)
    return TURNOS.get(int(numero.group())) if numero else None


# formatos de fecha que se aceptan en la tabla de OT: la celda de Excel con fecha llega como el primero
FORMATOS_FECHA = ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%d/%m/%Y %H:%M", "%d/%m/%Y", "%Y-%m-%d")


def fecha_de(texto: str) -> datetime | None:
    for formato in FORMATOS_FECHA:
        try:
            return datetime.strptime(texto.strip(), formato)
        except ValueError:
            continue
    return None


def si_o_no(texto: str) -> bool | None:
    """"Sí", "si", "No"; None si no es ninguno"""
    return {"si": True, "no": False}.get(normalizar(texto))


def numero_de(texto: str) -> Decimal | None:
    """Acepta coma o punto decimal; None si está vacío o no es un número"""
    try:
        return Decimal(texto.strip().replace(",", ".")) if texto.strip() else None
    except InvalidOperation:
        return None


def niveles_de_ubicacion(texto: str) -> tuple[str, ...]:
    """"Embotellado / Area 1 / Llenadora" -> niveles normalizados, para compararlos con los registrados"""
    return tuple(normalizar(n) for n in texto.split("/") if n.strip())
