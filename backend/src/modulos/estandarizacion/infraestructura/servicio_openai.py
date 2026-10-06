import openai

from src.compartido.configuracion import settings

from ..dominio.puertos import ServicioEstandarizacion, ServicioNoDisponible, TiempoAgotado
from .prompt_sistema import PROMPT_SISTEMA


class ServicioEstandarizacionOpenAI(ServicioEstandarizacion):
    def estandarizar(self, texto: str) -> str:
        if not settings.openai_api_key:
            raise ServicioNoDisponible()

        # sin reintentos, para que la espera nunca pase del tiempo límite
        cliente = openai.OpenAI(api_key=settings.openai_api_key, timeout=settings.openai_timeout_segundos, max_retries=0)
        try:
            respuesta = cliente.chat.completions.create(
                model=settings.openai_model,
                temperature=0.2,
                messages=[
                    {"role": "system", "content": PROMPT_SISTEMA},
                    {"role": "user", "content": texto},
                ],
            )
        except openai.APITimeoutError:  # va antes porque también es un error de conexión
            raise TiempoAgotado()
        except openai.OpenAIError:  # clave inválida, sin saldo, límite de uso, sin conexión
            raise ServicioNoDisponible()
        return respuesta.choices[0].message.content or ""
