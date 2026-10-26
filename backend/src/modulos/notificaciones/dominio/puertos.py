from abc import ABC, abstractmethod
from uuid import UUID


class RepositorioDispositivos(ABC):
    """Tokens de notificación de los celulares en los que cada usuario tiene la sesión abierta"""

    @abstractmethod
    def registrar(self, usuario_id: UUID, token: str) -> None:
        """Si el token ya era de otro usuario (otra persona entró en ese celular), pasa a este"""
        ...

    @abstractmethod
    def tokens_de(self, usuario_id: UUID) -> list[str]:
        ...

    @abstractmethod
    def eliminar(self, tokens: list[str]) -> None:
        ...


class ServicioNotificaciones(ABC):
    @abstractmethod
    def enviar(self, tokens: list[str], titulo: str, cuerpo: str) -> list[str]:
        """Envía la notificación a cada celular; devuelve los tokens que ya no sirven (app desinstalada o sesión cerrada)"""
        ...
