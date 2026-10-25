from datetime import time
from uuid import uuid4

import pytest

from src.modulos.acceso_roles.aplicacion.cambiar_estado_supervisor import SupervisorNoEncontrado
from src.modulos.acceso_roles.aplicacion.crear_supervisor import HorarioInvalido
from src.modulos.acceso_roles.aplicacion.editar_supervisor import editar_supervisor
from src.modulos.acceso_roles.aplicacion.gestionar_grupos import GrupoConTecnicos, GrupoNoEncontrado, eliminar_grupo
from src.modulos.acceso_roles.dominio.modelos import Grupo, Supervisor
from src.modulos.acceso_roles.dominio.puertos import GrupoEnUso
from tests.modulos.acceso_roles.repositorios_falsos import repositorios_de_grupos

TURNO_1 = (time(23), time(7))
TURNO_2 = (time(7), time(15))
TURNO_3 = (time(15), time(23))


def _supervisor(turno=TURNO_2, area="Embotellado"):
    return Supervisor(id=uuid4(), usuario_id=uuid4(), horario_entrada=turno[0], horario_salida=turno[1], area_designada=area)


def _grupo(nombre, supervisor=None):
    entrada, salida = (supervisor.horario_entrada, supervisor.horario_salida) if supervisor else TURNO_2
    return Grupo(id=uuid4(), nombre_de_grupo=nombre, supervisor_id=supervisor.id if supervisor else None,
                 horario_entrada=entrada, horario_salida=salida)


def _editar(supervisor, repositorios, turno=TURNO_1, area="Procesos", grupo_id=None):
    repositorio_supervisores, repositorio_grupos = repositorios
    return editar_supervisor(
        supervisor_id=supervisor.id, horario_entrada=turno[0], horario_salida=turno[1], area_designada=area,
        grupo_id=grupo_id, repositorio_supervisores=repositorio_supervisores, repositorio_grupos=repositorio_grupos,
    )


def test_cambia_turno_y_area_y_su_grupo_toma_el_nuevo_horario():
    ana = _supervisor()
    grupo = _grupo("Grupo 1", ana)
    repositorios = repositorios_de_grupos([ana], [grupo])

    editado = _editar(ana, repositorios, turno=TURNO_1, area="Procesos")

    assert (editado.horario_entrada, editado.horario_salida) == TURNO_1
    assert editado.area_designada == "Procesos"
    assert (grupo.horario_entrada, grupo.horario_salida) == TURNO_1


def test_area_vacia_se_guarda_como_sin_area():
    ana = _supervisor()
    repositorios = repositorios_de_grupos([ana], [_grupo("Grupo 1", ana)])

    assert _editar(ana, repositorios, area="   ").area_designada is None


def test_entrada_igual_a_salida_lanza_error():
    ana = _supervisor()
    repositorios = repositorios_de_grupos([ana], [_grupo("Grupo 1", ana)])

    with pytest.raises(HorarioInvalido):
        _editar(ana, repositorios, turno=(time(8), time(8)))


def test_supervisor_inexistente_lanza_error():
    with pytest.raises(SupervisorNoEncontrado):
        _editar(_supervisor(), repositorios_de_grupos([], []))


def test_al_cambiar_a_un_grupo_con_supervisor_se_intercambian_y_cada_grupo_toma_el_turno_de_su_supervisor():
    ana = _supervisor(turno=TURNO_2)
    luis = _supervisor(turno=TURNO_3)
    grupo_ana = _grupo("Grupo 1", ana)
    grupo_luis = _grupo("Grupo 2", luis)
    repositorios = repositorios_de_grupos([ana, luis], [grupo_ana, grupo_luis])

    _editar(ana, repositorios, turno=TURNO_1, grupo_id=grupo_luis.id)

    assert grupo_luis.supervisor_id == ana.id
    assert grupo_ana.supervisor_id == luis.id
    assert (grupo_luis.horario_entrada, grupo_luis.horario_salida) == TURNO_1  # el turno editado de Ana
    assert (grupo_ana.horario_entrada, grupo_ana.horario_salida) == TURNO_3  # el turno de Luis


def test_cambiar_a_un_grupo_inexistente_lanza_error():
    ana = _supervisor()
    repositorios = repositorios_de_grupos([ana], [_grupo("Grupo 1", ana)])

    with pytest.raises(GrupoNoEncontrado):
        _editar(ana, repositorios, grupo_id=uuid4())


def test_borra_un_grupo_sin_tecnicos():
    grupo = _grupo("Grupo por error")
    _, repositorio_grupos = repositorios_de_grupos([], [grupo])

    eliminar_grupo(grupo.id, repositorio_grupos)

    assert repositorio_grupos.obtener_por_id(grupo.id) is None


def test_no_borra_un_grupo_con_tecnicos():
    grupo = _grupo("Grupo 1")
    _, repositorio_grupos = repositorios_de_grupos([], [grupo], tecnicos_por_grupo={grupo.id: 3})

    with pytest.raises(GrupoConTecnicos) as error:
        eliminar_grupo(grupo.id, repositorio_grupos)

    assert error.value.cantidad == 3
    assert repositorio_grupos.obtener_por_id(grupo.id) is not None


def test_no_borra_un_grupo_con_comunicados():
    grupo = _grupo("Grupo 1")
    _, repositorio_grupos = repositorios_de_grupos([], [grupo], con_comunicados=[grupo.id])

    with pytest.raises(GrupoEnUso):
        eliminar_grupo(grupo.id, repositorio_grupos)


def test_borrar_un_grupo_inexistente_lanza_error():
    _, repositorio_grupos = repositorios_de_grupos([], [])

    with pytest.raises(GrupoNoEncontrado):
        eliminar_grupo(uuid4(), repositorio_grupos)
