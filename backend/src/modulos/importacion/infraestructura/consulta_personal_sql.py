from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from src.modulos.acceso_roles.infraestructura.orm import SupervisorORM, UsuarioORM

from ..dominio.puertos import ConsultaPersonal
from ..dominio.reglas import normalizar


def _nombre_completo(usuario: UsuarioORM) -> str:
    return normalizar(" ".join(p for p in (usuario.nombre, usuario.apellido_paterno, usuario.apellido_materno) if p))


class ConsultaPersonalSQL(ConsultaPersonal):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def nombres_completos(self) -> set[str]:
        return {_nombre_completo(u) for u in self._sesion.scalars(select(UsuarioORM)).all()}

    def nombres_de_usuario(self) -> set[str]:
        return set(self._sesion.scalars(select(UsuarioORM.nombre_usuario)).all())

    def supervisores_por_nombre(self) -> dict[str, UUID]:
        filas = self._sesion.execute(select(SupervisorORM.id, UsuarioORM).join(UsuarioORM, SupervisorORM.usuario_id == UsuarioORM.id)).all()
        return {_nombre_completo(usuario): supervisor_id for supervisor_id, usuario in filas}
