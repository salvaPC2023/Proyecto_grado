from uuid import UUID, uuid4

from src.compartido.configuracion import settings
from src.compartido.seguridad import hashear_password

from ..dominio.modelos import Profesion, Tecnico, Usuario
from ..dominio.puertos import RepositorioTecnicos, RepositorioUsuarios


class NombreUsuarioDuplicado(Exception):
    pass


def crear_tecnico(
    nombre: str,
    apellido_paterno: str,
    nombre_usuario: str,
    grupo_id: UUID,
    profesion: Profesion,
    creado_por_id: UUID,
    repositorio_usuarios: RepositorioUsuarios,
    repositorio_tecnicos: RepositorioTecnicos,
    apellido_materno: str | None = None,
) -> Tecnico:
    if repositorio_usuarios.obtener_por_nombre_usuario(nombre_usuario) is not None:
        raise NombreUsuarioDuplicado()

    usuario = Usuario(
        id=uuid4(),
        nombre=nombre,
        apellido_paterno=apellido_paterno,
        apellido_materno=apellido_materno,
        nombre_usuario=nombre_usuario,
        password_hash=hashear_password(settings.default_technician_password),
        activo=True,
        debe_cambiar_password=True,
    )
    usuario = repositorio_usuarios.crear(usuario)

    tecnico = Tecnico(
        id=uuid4(),
        usuario_id=usuario.id,
        grupo_id=grupo_id,
        profesion=profesion,
        creado_por_id=creado_por_id,
    )
    return repositorio_tecnicos.crear(tecnico)
