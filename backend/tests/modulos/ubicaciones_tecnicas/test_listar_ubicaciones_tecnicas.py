from uuid import uuid4

from src.modulos.ubicaciones_tecnicas.aplicacion.listar_ubicaciones_tecnicas import listar_ubicaciones_tecnicas
from src.modulos.ubicaciones_tecnicas.dominio.modelos import UbicacionTecnica
from tests.modulos.ordenes_trabajo.repositorios_falsos import RepositorioUbicacionesFalso


def test_devuelve_todas_las_ubicaciones():
    llenadora = UbicacionTecnica(id=uuid4(), sector="Embotellado", subsector="Area 1", sistema="Llenadora")
    caldera = UbicacionTecnica(id=uuid4(), sector="Servicios")
    repositorio = RepositorioUbicacionesFalso([llenadora, caldera])

    resultado = listar_ubicaciones_tecnicas(repositorio)

    assert resultado == [llenadora, caldera]

def test_sin_ubicaciones_devuelve_lista_vacia():
    repositorio = RepositorioUbicacionesFalso([])

    resultado = listar_ubicaciones_tecnicas(repositorio)

    assert resultado == []
