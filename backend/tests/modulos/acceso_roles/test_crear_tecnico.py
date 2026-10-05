from uuid import uuid4

import pytest

from src.compartido.configuracion import settings
from src.compartido.seguridad import verificar_password
from src.modulos.acceso_roles.aplicacion.crear_tecnico import NombreUsuarioDuplicado, crear_tecnico
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioTecnicosFalso, RepositorioUsuariosFalso, crear_usuario


def _crear(repositorio_usuarios, nombre_usuario="cmendoza"):
    return crear_tecnico(
        nombre="Carlos",
        apellido_paterno="Mendoza",
        nombre_usuario=nombre_usuario,
        grupo_id=uuid4(),
        profesion="electrico",
        creado_por_id=uuid4(),
        repositorio_usuarios=repositorio_usuarios,
        repositorio_tecnicos=RepositorioTecnicosFalso(),
    )


def test_crea_el_usuario_y_el_tecnico():
    repositorio_usuarios = RepositorioUsuariosFalso()

    tecnico = _crear(repositorio_usuarios)

    usuario = repositorio_usuarios.obtener_por_nombre_usuario("cmendoza")
    assert tecnico.usuario_id == usuario.id
    assert tecnico.profesion == "electrico"


def test_el_tecnico_nuevo_usa_la_password_inicial_y_debe_cambiarla():
    repositorio_usuarios = RepositorioUsuariosFalso()

    _crear(repositorio_usuarios)

    usuario = repositorio_usuarios.obtener_por_nombre_usuario("cmendoza")
    assert verificar_password(settings.default_technician_password, usuario.password_hash)
    assert usuario.debe_cambiar_password is True


def test_nombre_de_usuario_repetido_lanza_error():
    repositorio_usuarios = RepositorioUsuariosFalso([crear_usuario(nombre_usuario="cmendoza")])

    with pytest.raises(NombreUsuarioDuplicado):
        _crear(repositorio_usuarios, nombre_usuario="cmendoza")
