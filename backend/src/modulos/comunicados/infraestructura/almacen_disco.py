import re
from pathlib import Path
from uuid import uuid4

from src.compartido.configuracion import settings

from ..dominio.puertos import AlmacenImagenes

# solo nombres generados por el sistema: evita leer o borrar archivos fuera de la carpeta
_NOMBRE_VALIDO = re.compile(r"^[0-9a-f]{32}\.(jpg|png)$")


class AlmacenImagenesDisco(AlmacenImagenes):
    """Guarda las imágenes en una carpeta del servidor (COMUNICADOS_IMAGENES_DIR)"""

    def __init__(self, carpeta: str | Path | None = None):
        self._carpeta = Path(carpeta or settings.comunicados_imagenes_dir)

    def _ruta(self, nombre: str) -> Path | None:
        return self._carpeta / nombre if _NOMBRE_VALIDO.match(nombre) else None

    def guardar(self, contenido: bytes, extension: str) -> str:
        self._carpeta.mkdir(parents=True, exist_ok=True)
        nombre = f"{uuid4().hex}.{extension}"
        (self._carpeta / nombre).write_bytes(contenido)
        return nombre

    def leer(self, nombre: str) -> bytes | None:
        ruta = self._ruta(nombre)
        return ruta.read_bytes() if ruta and ruta.is_file() else None

    def eliminar(self, nombre: str) -> None:
        ruta = self._ruta(nombre)
        if ruta and ruta.is_file():
            ruta.unlink()
