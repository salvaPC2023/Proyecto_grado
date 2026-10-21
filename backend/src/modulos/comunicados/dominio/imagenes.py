TAMANO_MAXIMO = 2 * 1024 * 1024  # 2 MB

# se reconoce el formato por los primeros bytes del archivo, no por su nombre, que se puede falsear
_FIRMAS = {
    b"\xff\xd8\xff": "jpg",
    b"\x89PNG\r\n\x1a\n": "png",
}


def extension_de_imagen(contenido: bytes) -> str | None:
    """"jpg" o "png" según el contenido; None si no es una de esas imágenes"""
    return next((extension for firma, extension in _FIRMAS.items() if contenido.startswith(firma)), None)
