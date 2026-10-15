from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..dominio.puertos import RepositorioAdministradores
from .orm import AdministradorORM


class RepositorioAdministradoresSQL(RepositorioAdministradores):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def existe_alguno(self) -> bool:
        return self._sesion.scalars(select(AdministradorORM.id).limit(1)).first() is not None

    def crear(self, usuario_id: UUID) -> None:
        self._sesion.add(AdministradorORM(id=uuid4(), usuario_id=usuario_id))
        self._sesion.commit()
