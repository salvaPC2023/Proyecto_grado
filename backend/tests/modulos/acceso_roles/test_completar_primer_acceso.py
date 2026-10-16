import pytest

from src.compartido.seguridad import verificar_password
from src.modulos.acceso_roles.aplicacion.cambiar_password import PasswordDebil
from src.modulos.acceso_roles.aplicacion.completar_primer_acceso import (
    NombreUsuarioEnUso,
    NombreUsuarioInvalido,
    PrimerAccesoYaCompletado,
    completar_primer_acceso,
)
from src.modulos.acceso_roles.aplicacion.iniciar_sesion import iniciar_sesion
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


def _recien_creado(nombre_usuario="mqjgeubu"):
    usuario = crear_usuario(nombre_usuario=nombre_usuario, password="ESPODI2026")
    usuario.debe_cambiar_password = True
    return usuario


def test_el_login_avisa_que_debe_cambiar_sus_credenciales():
    repositorio = RepositorioUsuariosFalso([_recien_creado()])

    resultado = iniciar_sesion("mqjgeubu", "ESPODI2026", repositorio)

    assert resultado.debe_cambiar_credenciales is True


def test_cambia_usuario_y_password_y_ya_no_debe_cambiarlos():
    usuario = _recien_creado()
    repositorio = RepositorioUsuariosFalso([usuario])

    completar_primer_acceso(usuario.id, "Cmamani", "Segura#26", repositorio)

    assert usuario.nombre_usuario == "cmamani"  # se guarda en minúsculas
    assert verificar_password("Segura#26", usuario.password_hash)
    assert usuario.debe_cambiar_password is False
    assert repositorio.obtener_por_nombre_usuario("mqjgeubu") is None
    assert iniciar_sesion("cmamani", "Segura#26", repositorio).debe_cambiar_credenciales is False


def test_puede_conservar_el_usuario_generado():
    usuario = _recien_creado()
    repositorio = RepositorioUsuariosFalso([usuario])

    completar_primer_acceso(usuario.id, "mqjgeubu", "Segura#26", repositorio)

    assert usuario.nombre_usuario == "mqjgeubu"


def test_no_puede_quedarse_con_la_password_inicial():
    usuario = _recien_creado()

    with pytest.raises(PasswordDebil):
        completar_primer_acceso(usuario.id, "cmamani", "ESPODI2026", RepositorioUsuariosFalso([usuario]))


def test_password_debil_lanza_error():
    usuario = _recien_creado()

    with pytest.raises(PasswordDebil):
        completar_primer_acceso(usuario.id, "cmamani", "corta", RepositorioUsuariosFalso([usuario]))


@pytest.mark.parametrize("nombre_usuario", ["abc", "nueveletr", "c.mamani", "c mamani"])
def test_usuario_fuera_de_la_regla_lanza_error(nombre_usuario):
    usuario = _recien_creado()

    with pytest.raises(NombreUsuarioInvalido):
        completar_primer_acceso(usuario.id, nombre_usuario, "Segura#26", RepositorioUsuariosFalso([usuario]))


def test_usuario_de_otra_persona_lanza_error():
    usuario = _recien_creado()
    repositorio = RepositorioUsuariosFalso([usuario, crear_usuario(nombre_usuario="cmamani")])

    with pytest.raises(NombreUsuarioEnUso):
        completar_primer_acceso(usuario.id, "cmamani", "Segura#26", repositorio)


def test_no_se_puede_repetir_si_ya_lo_completo():
    usuario = crear_usuario(nombre_usuario="cmamani")  # debe_cambiar_password=False

    with pytest.raises(PrimerAccesoYaCompletado):
        completar_primer_acceso(usuario.id, "otro", "Segura#26", RepositorioUsuariosFalso([usuario]))
