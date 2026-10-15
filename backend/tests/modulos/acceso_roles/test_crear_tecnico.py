from uuid import uuid4

from src.compartido.configuracion import settings
from src.compartido.seguridad import verificar_password
from src.modulos.acceso_roles.aplicacion.crear_tecnico import crear_tecnico
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioTecnicosFalso, RepositorioUsuariosFalso


def _crear(repositorio_usuarios):
    return crear_tecnico(
        nombre="Carlos",
        apellido_paterno="Mendoza",
        apellido_materno="Quispe",
        grupo_id=uuid4(),
        profesion="electrico",
        creado_por_id=uuid4(),
        repositorio_usuarios=repositorio_usuarios,
        repositorio_tecnicos=RepositorioTecnicosFalso(),
    )


def test_crea_el_usuario_y_el_tecnico():
    repositorio_usuarios = RepositorioUsuariosFalso()

    tecnico = _crear(repositorio_usuarios)

    assert repositorio_usuarios.obtener_por_id(tecnico.usuario_id) is not None
    assert tecnico.profesion == "electrico"


def test_el_usuario_se_genera_con_las_iniciales_de_los_apellidos():
    repositorio_usuarios = RepositorioUsuariosFalso()

    tecnico = _crear(repositorio_usuarios)

    nombre_usuario = repositorio_usuarios.obtener_por_id(tecnico.usuario_id).nombre_usuario
    assert len(nombre_usuario) == 8
    assert nombre_usuario.startswith("mq")


def test_el_tecnico_nuevo_usa_la_password_inicial_y_debe_cambiarla():
    repositorio_usuarios = RepositorioUsuariosFalso()

    tecnico = _crear(repositorio_usuarios)

    usuario = repositorio_usuarios.obtener_por_id(tecnico.usuario_id)
    assert verificar_password(settings.default_technician_password, usuario.password_hash)
    assert usuario.debe_cambiar_password is True
