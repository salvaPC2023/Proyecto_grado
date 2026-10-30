from datetime import datetime
from uuid import uuid4

from sqlalchemy.orm import Session

from ..dominio.puertos import AlmacenImagenes
from .orm import ImagenComunicadoORM


class AlmacenImagenesPostgres(AlmacenImagenes):
    """Guarda las imágenes dentro de la base de datos. Se usa en servidores cuyo disco se borra al reiniciar
    (Render gratuito): así la imagen se conserva junto con su comunicado y entra en el mismo respaldo"""

    def __init__(self, sesion: Session):
        self._sesion = sesion

    def guardar(self, contenido: bytes, extension: str) -> str:
        nombre = f"{uuid4().hex}.{extension}"
        self._sesion.add(ImagenComunicadoORM(nombre=nombre, contenido=contenido, creada=datetime.now()))
        self._sesion.commit()
        return nombre

    def leer(self, nombre: str) -> bytes | None:
        imagen = self._sesion.get(ImagenComunicadoORM, nombre)
        return imagen.contenido if imagen else None

    def eliminar(self, nombre: str) -> None:
        imagen = self._sesion.get(ImagenComunicadoORM, nombre)
        if imagen is not None:
            self._sesion.delete(imagen)
            self._sesion.commit()
