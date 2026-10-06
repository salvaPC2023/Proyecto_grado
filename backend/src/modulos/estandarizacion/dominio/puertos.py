from abc import ABC, abstractmethod


class ServicioNoDisponible(Exception):
    """El proveedor falló, rechazó la clave o llegó a su límite de uso"""


class TiempoAgotado(Exception):
    """El modelo no respondió dentro del tiempo límite"""


class ServicioEstandarizacion(ABC):
    @abstractmethod
    def estandarizar(self, texto: str) -> str:
        """Devuelve el texto estandarizado; lanza ServicioNoDisponible o TiempoAgotado"""
        ...
