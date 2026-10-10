from abc import ABC, abstractmethod
from uuid import UUID


class PlantillaInvalida(Exception):
    """El archivo no es un Excel o no tiene las tablas de la plantilla"""

    def __init__(self, mensaje: str):
        super().__init__(mensaje)
        self.mensaje = mensaje


class ConsultaPersonal(ABC):
    """Lo que la importación necesita saber de los usuarios ya registrados"""

    @abstractmethod
    def nombres_completos(self) -> set[str]:
        """Nombres completos (normalizados) de todos los usuarios"""
        ...

    @abstractmethod
    def nombres_de_usuario(self) -> set[str]:
        ...

    @abstractmethod
    def supervisores_por_nombre(self) -> dict[str, UUID]:
        """Nombre completo normalizado -> id del supervisor"""
        ...
