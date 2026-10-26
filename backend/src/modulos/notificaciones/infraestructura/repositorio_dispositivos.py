from datetime import datetime
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from ..dominio.puertos import RepositorioDispositivos
from .orm import DispositivoORM


class RepositorioDispositivosSQL(RepositorioDispositivos):
    def __init__(self, sesion: Session):
        self._sesion = sesion

    def registrar(self, usuario_id: UUID, token: str) -> None:
        dispositivo = self._sesion.get(DispositivoORM, token)
        if dispositivo is None:
            self._sesion.add(DispositivoORM(token=token, usuario_id=usuario_id, actualizado=datetime.now()))
        else:
            dispositivo.usuario_id = usuario_id
            dispositivo.actualizado = datetime.now()
        self._sesion.commit()

    def tokens_de(self, usuario_id: UUID) -> list[str]:
        return list(self._sesion.scalars(select(DispositivoORM.token).where(DispositivoORM.usuario_id == usuario_id)).all())

    def eliminar(self, tokens: list[str]) -> None:
        self._sesion.execute(delete(DispositivoORM).where(DispositivoORM.token.in_(tokens)))
        self._sesion.commit()
