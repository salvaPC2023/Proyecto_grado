from uuid import uuid4

import pytest

from src.compartido.seguridad import hashear_password
from src.modulos.acceso_roles.aplicacion.iniciar_sesion import (
    CredencialesInvalidas,
    CuentaDeshabilitada,
    iniciar_sesion,
)
from src.modulos.acceso_roles.dominio.modelos import Usuario
from src.modulos.acceso_roles.dominio.puertos import RepositorioUsuarios


class RepositorioUsuariosFalso(RepositorioUsuarios):
    """Vive en memoria, sin Postgres — solo para probar aplicacion/ aislada."""

    def __init__(self, usuarios: list[Usuario], rol: str = "tecnico"):
        self._usuarios = {u.nombre_usuario: u for u in usuarios}
        self._rol = rol

    def obtener_por_nombre_usuario(self, nombre_usuario):
        return self._usuarios.get(nombre_usuario)

    def obtener_por_id(self, id):
        return next((u for u in self._usuarios.values() if u.id == id), None)

    def obtener_rol(self, usuario_id):
        return self._rol

    def crear(self, usuario):
        self._usuarios[usuario.nombre_usuario] = usuario
        return usuario

    def actualizar(self, usuario):
        self._usuarios[usuario.nombre_usuario] = usuario
        return usuario


def _crear_usuario(nombre_usuario="tecnico01", password="clave123", activo=True):
    return Usuario(
        id=uuid4(),
        nombre="Juan",
        apellido_paterno="Perez",
        nombre_usuario=nombre_usuario,
        password_hash=hashear_password(password),
        activo=activo,
        debe_cambiar_password=False,
    )


def test_login_correcto_devuelve_token_y_rol():
    usuario = _crear_usuario()
    repo = RepositorioUsuariosFalso([usuario], rol="tecnico")

    resultado = iniciar_sesion("tecnico01", "clave123", repo)

    assert resultado.token
    assert resultado.rol == "tecnico"


def test_usuario_inexistente_lanza_credenciales_invalidas():
    repo = RepositorioUsuariosFalso([])

    with pytest.raises(CredencialesInvalidas):
        iniciar_sesion("no_existe", "cualquiera", repo)


def test_password_incorrecta_lanza_credenciales_invalidas():
    usuario = _crear_usuario(password="clave123")
    repo = RepositorioUsuariosFalso([usuario])

    with pytest.raises(CredencialesInvalidas):
        iniciar_sesion("tecnico01", "password_mala", repo)


def test_usuario_deshabilitado_lanza_cuenta_deshabilitada():
    usuario = _crear_usuario(activo=False)
    repo = RepositorioUsuariosFalso([usuario])

    with pytest.raises(CuentaDeshabilitada):
        iniciar_sesion("tecnico01", "clave123", repo)
