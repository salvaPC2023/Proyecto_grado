from datetime import time
from uuid import uuid4

import pytest

from src.compartido.configuracion import settings
from src.compartido.seguridad import verificar_password
from src.modulos.acceso_roles.aplicacion.cambiar_estado_supervisor import SupervisorNoEncontrado, cambiar_estado_supervisor
from src.modulos.acceso_roles.aplicacion.crear_supervisor import HorarioInvalido, crear_supervisor
from src.modulos.acceso_roles.aplicacion.crear_tecnico import NombreUsuarioDuplicado
from src.modulos.acceso_roles.aplicacion.listar_supervisores import listar_supervisores
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioSupervisoresFalso, RepositorioUsuariosFalso, crear_supervisor as supervisor_de, crear_usuario


def _crear(repositorio_usuarios, repositorio_supervisores, nombre_usuario="aperez", entrada=time(7), salida=time(15)):
    return crear_supervisor(
        nombre="Ana",
        apellido_paterno="Perez",
        nombre_usuario=nombre_usuario,
        nombre_de_grupo="Grupo Suministros",
        horario_entrada=entrada,
        horario_salida=salida,
        repositorio_usuarios=repositorio_usuarios,
        repositorio_supervisores=repositorio_supervisores,
    )


def test_crea_el_supervisor_con_su_grupo():
    repositorio_supervisores = RepositorioSupervisoresFalso()

    supervisor = _crear(RepositorioUsuariosFalso(), repositorio_supervisores)

    grupo = repositorio_supervisores.obtener_grupo(supervisor.id)
    assert grupo.nombre_de_grupo == "Grupo Suministros"
    assert grupo.horario_entrada == time(7)  # el grupo toma el horario del supervisor


def test_el_supervisor_nuevo_usa_la_password_inicial_y_debe_cambiarla():
    repositorio_usuarios = RepositorioUsuariosFalso()

    _crear(repositorio_usuarios, RepositorioSupervisoresFalso())

    usuario = repositorio_usuarios.obtener_por_nombre_usuario("aperez")
    assert verificar_password(settings.default_technician_password, usuario.password_hash)
    assert usuario.debe_cambiar_password is True


def test_se_permite_un_turno_de_noche():
    supervisor = _crear(RepositorioUsuariosFalso(), RepositorioSupervisoresFalso(), entrada=time(23), salida=time(7))

    assert supervisor.horario_salida == time(7)


def test_nombre_de_usuario_repetido_lanza_error():
    repositorio_usuarios = RepositorioUsuariosFalso([crear_usuario(nombre_usuario="aperez")])

    with pytest.raises(NombreUsuarioDuplicado):
        _crear(repositorio_usuarios, RepositorioSupervisoresFalso())


def test_entrada_igual_a_salida_lanza_error():
    with pytest.raises(HorarioInvalido):
        _crear(RepositorioUsuariosFalso(), RepositorioSupervisoresFalso(), entrada=time(8), salida=time(8))


def test_lista_todos_los_supervisores():
    repositorio_supervisores = RepositorioSupervisoresFalso([supervisor_de(uuid4()), supervisor_de(uuid4())])

    assert len(listar_supervisores(repositorio_supervisores)) == 2


def test_deshabilita_la_cuenta_del_supervisor():
    usuario = crear_usuario(nombre_usuario="aperez")
    supervisor = supervisor_de(usuario.id)

    cambiar_estado_supervisor(supervisor.id, False, RepositorioSupervisoresFalso([supervisor]), RepositorioUsuariosFalso([usuario]))

    assert usuario.activo is False


def test_supervisor_inexistente_lanza_error():
    with pytest.raises(SupervisorNoEncontrado):
        cambiar_estado_supervisor(uuid4(), False, RepositorioSupervisoresFalso(), RepositorioUsuariosFalso())
