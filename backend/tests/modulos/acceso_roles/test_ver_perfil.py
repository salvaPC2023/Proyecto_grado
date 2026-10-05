from datetime import time
from uuid import uuid4

import pytest

from src.modulos.acceso_roles.aplicacion.ver_perfil import ver_perfil
from src.modulos.acceso_roles.dominio.modelos import Grupo
from tests.modulos.acceso_roles.repositorios_falsos import (
    RepositorioSupervisoresFalso,
    RepositorioTecnicosFalso,
    RepositorioUsuariosFalso,
    crear_supervisor,
    crear_tecnico_de,
    crear_usuario,
)


def test_el_tecnico_ve_su_profesion_y_su_grupo():
    usuario = crear_usuario()
    tecnico = crear_tecnico_de(usuario, profesion="electrico")
    repositorio_tecnicos = RepositorioTecnicosFalso([tecnico], nombre_de_grupo={tecnico.grupo_id: "Grupo 1"})

    perfil = ver_perfil(usuario.id, "tecnico", RepositorioUsuariosFalso([usuario]), repositorio_tecnicos, RepositorioSupervisoresFalso())

    assert perfil.profesion == "electrico"
    assert perfil.grupo_nombre == "Grupo 1"


def test_el_supervisor_ve_su_horario():
    usuario = crear_usuario(nombre_usuario="ana")
    repositorio_supervisores = RepositorioSupervisoresFalso([crear_supervisor(usuario.id)])

    perfil = ver_perfil(usuario.id, "supervisor", RepositorioUsuariosFalso([usuario]), RepositorioTecnicosFalso(), repositorio_supervisores)

    assert perfil.horario_entrada == time(8)
    assert perfil.area_designada == "Embotellado"


def test_el_supervisor_ve_su_grupo_a_cargo():
    usuario = crear_usuario(nombre_usuario="ana")
    supervisor = crear_supervisor(usuario.id)
    repositorio_supervisores = RepositorioSupervisoresFalso([supervisor])
    repositorio_supervisores.grupos[supervisor.id] = Grupo(id=uuid4(), nombre_de_grupo="Grupo Suministros", supervisor_id=supervisor.id, horario_entrada=time(8), horario_salida=time(17))

    perfil = ver_perfil(usuario.id, "supervisor", RepositorioUsuariosFalso([usuario]), RepositorioTecnicosFalso(), repositorio_supervisores)

    assert perfil.grupo_nombre == "Grupo Suministros"


def test_usuario_inexistente_lanza_error():
    with pytest.raises(ValueError):
        ver_perfil(uuid4(), "tecnico", RepositorioUsuariosFalso(), RepositorioTecnicosFalso(), RepositorioSupervisoresFalso())
