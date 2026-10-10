import re
import unicodedata

from src.modulos.acceso_roles.dominio.modelos import Profesion

# "Grupo Planificador" de SAP -> profesión del sistema; electrónico se registra como electromecánico
PROFESIONES: dict[str, Profesion] = {
    "mecanico": "mecanico",
    "electrico": "electrico",
    "electromecanico": "electromecanico",
    "electronico": "electromecanico",
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


def generar_nombre_usuario(nombre: str, apellido_paterno: str, apellido_materno: str | None, ocupados: set[str]) -> str:
    """Inicial del nombre + apellido paterno (cmamani); si está ocupado, + inicial del materno (pvargasm); si no, un número"""
    def limpio(texto: str) -> str:
        return re.sub(r"[^a-z]", "", normalizar(texto))

    base = limpio(nombre)[:1] + limpio(apellido_paterno)
    candidatos = [base]
    if apellido_materno:
        candidatos.append(base + limpio(apellido_materno)[:1])
    for candidato in candidatos:
        if candidato not in ocupados:
            return candidato
    numero = 2
    while f"{candidatos[-1]}{numero}" in ocupados:
        numero += 1
    return f"{candidatos[-1]}{numero}"
