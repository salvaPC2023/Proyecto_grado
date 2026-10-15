import re
import secrets
import unicodedata
from collections.abc import Callable

LONGITUD = 8
# sin 0/o ni 1/l/i, para que no se confundan al dictar o leer el usuario
ALFABETO = "abcdefghjkmnpqrstuvwxyz23456789"


def _inicial(texto: str) -> str:
    sin_tildes = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode().lower()
    letras = re.sub(r"[^a-z]", "", sin_tildes)
    return letras[:1] or "x"


def generar_nombre_usuario(
    nombre: str,
    apellido_paterno: str,
    apellido_materno: str | None,
    esta_ocupado: Callable[[str], bool],
) -> str:
    """Inicial del apellido paterno + inicial del materno (o del nombre si no tiene) + 6 caracteres al azar"""
    prefijo = _inicial(apellido_paterno) + _inicial(apellido_materno or nombre)
    while True:
        candidato = prefijo + "".join(secrets.choice(ALFABETO) for _ in range(LONGITUD - len(prefijo)))
        if not esta_ocupado(candidato):
            return candidato
