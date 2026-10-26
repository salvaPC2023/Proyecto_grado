import logging
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, messaging

from src.compartido.configuracion import settings

from ..dominio.puertos import ServicioNotificaciones

registro = logging.getLogger("uvicorn.error")
CARPETA_BACKEND = Path(__file__).resolve().parents[4]


def _aplicacion() -> firebase_admin.App | None:
    """La app de Firebase se inicia una sola vez; sin el archivo de la cuenta de servicio no se envía nada"""
    try:
        return firebase_admin.get_app()
    except ValueError:
        pass
    ruta = Path(settings.firebase_credenciales)
    ruta = ruta if ruta.is_absolute() else CARPETA_BACKEND / ruta
    if not ruta.exists():
        registro.warning("Notificaciones desactivadas: no existe %s", ruta)
        return None
    return firebase_admin.initialize_app(credentials.Certificate(str(ruta)))


class ServicioNotificacionesFirebase(ServicioNotificaciones):
    def enviar(self, tokens: list[str], titulo: str, cuerpo: str) -> list[str]:
        if not tokens or _aplicacion() is None:
            return []
        mensajes = [
            messaging.Message(
                token=token,
                notification=messaging.Notification(title=titulo, body=cuerpo),
                # alta prioridad: debe llegar aunque el celular esté en reposo
                android=messaging.AndroidConfig(priority="high"),
            )
            for token in tokens
        ]
        respuesta = messaging.send_each(mensajes)
        invalidos = []
        for token, envio in zip(tokens, respuesta.responses):
            if envio.success:
                continue
            if isinstance(envio.exception, (messaging.UnregisteredError, messaging.SenderIdMismatchError)):
                invalidos.append(token)
            else:
                registro.warning("Notificación no enviada: %s", envio.exception)
        return invalidos
