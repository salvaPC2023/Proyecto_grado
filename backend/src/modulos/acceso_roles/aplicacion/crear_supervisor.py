from datetime import time
from uuid import uuid4

from src.compartido.configuracion import settings
from src.compartido.seguridad import hashear_password

from ..dominio.modelos import Grupo, Supervisor, Usuario
from ..dominio.puertos import RepositorioSupervisores, RepositorioUsuarios
from .crear_tecnico import NombreUsuarioDuplicado


class HorarioInvalido(Exception):
    pass


def crear_supervisor(
    nombre: str,
    apellido_paterno: str,
    nombre_usuario: str,
    nombre_de_grupo: str,
    horario_entrada: time,
    horario_salida: time,
    repositorio_usuarios: RepositorioUsuarios,
    repositorio_supervisores: RepositorioSupervisores,
    apellido_materno: str | None = None,
    area_designada: str | None = None,
) -> Supervisor:
    if repositorio_usuarios.obtener_por_nombre_usuario(nombre_usuario) is not None:
        raise NombreUsuarioDuplicado()
    if horario_entrada == horario_salida:
        raise HorarioInvalido()

    usuario = repositorio_usuarios.crear(Usuario(
        id=uuid4(),
        nombre=nombre,
        apellido_paterno=apellido_paterno,
        apellido_materno=apellido_materno,
        nombre_usuario=nombre_usuario,
        password_hash=hashear_password(settings.default_technician_password),
        activo=True,
        debe_cambiar_password=True,
    ))
    supervisor = Supervisor(
        id=uuid4(),
        usuario_id=usuario.id,
        horario_entrada=horario_entrada,
        horario_salida=horario_salida,
        area_designada=area_designada,
    )
    # cada supervisor tiene un solo grupo, con su mismo horario
    grupo = Grupo(
        id=uuid4(),
        nombre_de_grupo=nombre_de_grupo,
        supervisor_id=supervisor.id,
        horario_entrada=horario_entrada,
        horario_salida=horario_salida,
    )
    return repositorio_supervisores.crear(supervisor, grupo)
