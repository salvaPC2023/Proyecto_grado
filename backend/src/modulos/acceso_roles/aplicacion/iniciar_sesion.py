from typing import NamedTuple
from src.compartido.seguridad import crear_token, verificar_password
from ..dominio.puertos import RepositorioUsuarios

class CredencialesInvalidas(Exception):
    pass

class CuentaDeshabilitada(Exception):
    pass

class ResultadoInicioSesion(NamedTuple):
    token: str
    rol: str
    # recién creado: el token solo sirve para cambiar usuario y contraseña
    debe_cambiar_credenciales: bool = False

def iniciar_sesion(nombre_usuario: str, password: str, repositorio: RepositorioUsuarios,) -> ResultadoInicioSesion:
    usuario = repositorio.obtener_por_nombre_usuario(nombre_usuario)
    if usuario is None or not verificar_password(password, usuario.password_hash):
        raise CredencialesInvalidas()

    if not usuario.activo:
        raise CuentaDeshabilitada()

    rol = repositorio.obtener_rol(usuario.id)
    token = crear_token(usuario.id, rol)
    
    return ResultadoInicioSesion(token=token, rol=rol, debe_cambiar_credenciales=usuario.debe_cambiar_password)
