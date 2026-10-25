import logging

import openai

from src.compartido.configuracion import settings

from ..dominio.puertos import ServicioEstandarizacion, ServicioNoDisponible, TiempoAgotado
from .prompt_sistema import PROMPT_SISTEMA

registro = logging.getLogger("uvicorn.error")


class ServicioEstandarizacionOpenAI(ServicioEstandarizacion):
    def estandarizar(self, texto: str) -> str:
        if not settings.openai_api_key:
            registro.warning("Estandarización no disponible: OPENAI_API_KEY está vacía en .env")
            raise ServicioNoDisponible()

        # sin reintentos, para que la espera nunca pase del tiempo límite
        cliente = openai.OpenAI(api_key=settings.openai_api_key, timeout=settings.openai_timeout_segundos, max_retries=0)
        try:
            respuesta = cliente.chat.completions.create(
                model=settings.openai_model,
                temperature=0.2,
                max_tokens=768,
                messages=[
                    {"role": "system", "content": PROMPT_SISTEMA},
                    {"role": "user", "content": texto},
                ],
            )
        except openai.APITimeoutError:  # va antes porque también es un error de conexión
            registro.warning("Estandarización: OpenAI no respondió en %s s", settings.openai_timeout_segundos)
            raise TiempoAgotado()
        except openai.OpenAIError as error:  # clave inválida, sin saldo, límite de uso, sin conexión
            registro.warning("Estandarización: OpenAI rechazó la llamada (%s: %s)", type(error).__name__, error)
            raise ServicioNoDisponible()
        return respuesta.choices[0].message.content or ""
