from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..dominio.modelos import Usuario
from ..dominio.puertos import Rol, RepositorioUsuarios
from .orm import SupervisorORM, TecnicoORM, UsuarioORM


def _a_dominio(orm: UsuarioORM) -> Usuario:
    return Usuario(
        id=orm.id,
        nombre=orm.nombre,
        apellido_paterno=orm.apellido_paterno,
        apellido_materno=orm.apellido_materno,
        nombre_usuario=orm.nombre_usuario,
        password_hash=orm.password_hash,
        activo=orm.activo,
        debe_cambiar_password=orm.debe_cambiar_password,
    )


class RepositorioUsuariosSQL(RepositorioUsuarios):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def obtener_por_nombre_usuario(self, nombre_usuario: str) -> Usuario | None:
        orm = self._sesion.scalars(
            select(UsuarioORM).where(UsuarioORM.nombre_usuario == nombre_usuario)
        ).first()
        return _a_dominio(orm) if orm else None

    def obtener_por_id(self, id: UUID) -> Usuario | None:
        orm = self._sesion.get(UsuarioORM, id)
        return _a_dominio(orm) if orm else None

    def obtener_rol(self, usuario_id: UUID) -> Rol:
        es_supervisor = self._sesion.scalars(
            select(SupervisorORM).where(SupervisorORM.usuario_id == usuario_id)
        ).first()
        if es_supervisor is not None:
            return "supervisor"

        es_tecnico = self._sesion.scalars(
            select(TecnicoORM).where(TecnicoORM.usuario_id == usuario_id)
        ).first()
        if es_tecnico is not None:
            return "tecnico"

        raise ValueError(
            f"El usuario {usuario_id} no está en Supervisores ni en Tecnicos"
        )

    def crear(self, usuario: Usuario) -> Usuario:
        orm = UsuarioORM(
            id=usuario.id,
            nombre=usuario.nombre,
            apellido_paterno=usuario.apellido_paterno,
            apellido_materno=usuario.apellido_materno,
            nombre_usuario=usuario.nombre_usuario,
            password_hash=usuario.password_hash,
            activo=usuario.activo,
            debe_cambiar_password=usuario.debe_cambiar_password,
        )
        self._sesion.add(orm)
        self._sesion.commit()
        self._sesion.refresh(orm)
        return _a_dominio(orm)

    def actualizar(self, usuario: Usuario) -> Usuario:
        orm = self._sesion.get(UsuarioORM, usuario.id)
        orm.nombre = usuario.nombre
        orm.apellido_paterno = usuario.apellido_paterno
        orm.apellido_materno = usuario.apellido_materno
        orm.nombre_usuario = usuario.nombre_usuario
        orm.password_hash = usuario.password_hash
        orm.activo = usuario.activo
        orm.debe_cambiar_password = usuario.debe_cambiar_password
        self._sesion.commit()
        self._sesion.refresh(orm)
        return _a_dominio(orm)
