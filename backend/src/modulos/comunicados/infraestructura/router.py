import logging
from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Response, UploadFile, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from src.compartido.bd import get_db
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, obtener_usuario_actual, requerir_supervisor
from src.modulos.acceso_roles.infraestructura.repositorio_supervisores import RepositorioSupervisoresSQL
from src.modulos.acceso_roles.infraestructura.repositorio_tecnicos import RepositorioTecnicosSQL
from src.modulos.acceso_roles.infraestructura.repositorio_usuarios import RepositorioUsuariosSQL
from src.modulos.notificaciones.aplicacion.avisos import avisar, aviso_de_comunicado_personal
from src.modulos.notificaciones.infraestructura.repositorio_dispositivos import RepositorioDispositivosSQL
from src.modulos.notificaciones.infraestructura.servicio_firebase import ServicioNotificacionesFirebase

from ..aplicacion.gestionar_comunicados import (
    ComunicadoNoEncontrado, ComunicadoVacio, ExpiracionInvalida, ImagenInvalida, NoEsElAutor, SupervisorSinGrupo,
    TecnicoAjeno, TituloVacio, listar_comunicados, obtener_imagen, publicar_comunicado, retirar_comunicado,
)
from ..dominio.imagenes import TAMANO_MAXIMO
from ..dominio.modelos import Categoria, Comunicado
from src.compartido.configuracion import settings

from ..dominio.puertos import AlmacenImagenes
from .almacen_disco import AlmacenImagenesDisco
from .almacen_postgres import AlmacenImagenesPostgres
from .repositorio_comunicados import RepositorioComunicadosSQL

router_comunicados = APIRouter(prefix="/comunicados", tags=["comunicados"])
registro = logging.getLogger("uvicorn.error")

TIPOS_IMAGEN = {"jpg": "image/jpeg", "png": "image/png"}


class ComunicadoOut(BaseModel):
    id: UUID
    titulo: str
    texto: str | None
    categoria: Categoria
    tiene_imagen: bool
    personal: bool
    fecha_envio: datetime
    fecha_expiracion: datetime
    autor_nombre: str  # para el técnico: quién lo escribió
    destinatario_nombre: str | None  # para el supervisor: a quién iba, si es personal


class _Nombres:
    """Nombres de supervisores y técnicos para mostrar en la app, consultados una sola vez cada uno"""

    def __init__(self, db: Session):
        self._usuarios = RepositorioUsuariosSQL(db)
        self._supervisores = RepositorioSupervisoresSQL(db)
        self._tecnicos = RepositorioTecnicosSQL(db)
        self._cache: dict[UUID, str] = {}

    def _de_usuario(self, usuario_id: UUID) -> str:
        if usuario_id not in self._cache:
            u = self._usuarios.obtener_por_id(usuario_id)
            self._cache[usuario_id] = " ".join(p for p in (u.nombre, u.apellido_paterno, u.apellido_materno) if p) if u else ""
        return self._cache[usuario_id]

    def supervisor(self, supervisor_id: UUID) -> str:
        supervisor = self._supervisores.obtener_por_id(supervisor_id)
        return self._de_usuario(supervisor.usuario_id) if supervisor else ""

    def tecnico(self, tecnico_id: UUID | None) -> str | None:
        if tecnico_id is None:
            return None
        tecnico = self._tecnicos.obtener_por_id(tecnico_id)
        return self._de_usuario(tecnico.usuario_id) if tecnico else None


def a_comunicado_out(comunicado: Comunicado, nombres: _Nombres) -> ComunicadoOut:
    return ComunicadoOut(
        id=comunicado.id, titulo=comunicado.titulo, texto=comunicado.texto, categoria=comunicado.categoria,
        tiene_imagen=comunicado.imagen is not None, personal=comunicado.es_personal,
        fecha_envio=comunicado.fecha_envio, fecha_expiracion=comunicado.fecha_expiracion,
        autor_nombre=nombres.supervisor(comunicado.supervisor_id), destinatario_nombre=nombres.tecnico(comunicado.tecnico_id),
    )


def _avisar_al_destinatario(comunicado: Comunicado, nombres: _Nombres, db: Session) -> None:
    """Notificación push al celular del técnico; si Firebase falla, el comunicado ya quedó publicado igual"""
    tecnico = RepositorioTecnicosSQL(db).obtener_por_id(comunicado.tecnico_id)
    if tecnico is None:
        return
    aviso = aviso_de_comunicado_personal(tecnico.usuario_id, nombres.supervisor(comunicado.supervisor_id), comunicado.titulo)
    try:
        avisar(aviso, RepositorioDispositivosSQL(db), ServicioNotificacionesFirebase())
    except Exception:
        registro.exception("No se pudo notificar el comunicado personal")


def _almacen(db: Session) -> AlmacenImagenes:
    """En la PC las imágenes van a una carpeta; en un servidor sin disco persistente, a la base de datos"""
    return AlmacenImagenesPostgres(db) if settings.comunicados_almacen == "postgres" else AlmacenImagenesDisco()


def _error(codigo: int, detalle: str) -> HTTPException:
    return HTTPException(status_code=codigo, detail=detalle)


@router_comunicados.post("", response_model=ComunicadoOut, status_code=status.HTTP_201_CREATED)
async def publicar_comunicado_endpoint(
    titulo: str = Form(max_length=100),
    categoria: Categoria = Form(),
    fecha_expiracion: datetime = Form(),
    texto: str | None = Form(default=None, max_length=2000),
    tecnico_id: UUID | None = Form(default=None),
    imagen: UploadFile | None = File(default=None),
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_supervisor),
):
    """Sin tecnico_id es general para todo el grupo; con tecnico_id es personal"""
    contenido = await imagen.read(TAMANO_MAXIMO + 1) if imagen else None
    try:
        comunicado = publicar_comunicado(
            actual.id, titulo, categoria, fecha_expiracion,
            RepositorioComunicadosSQL(db), RepositorioSupervisoresSQL(db), RepositorioTecnicosSQL(db), _almacen(db),
            ahora=datetime.now(), texto=texto, imagen=contenido, tecnico_id=tecnico_id,
        )
    except SupervisorSinGrupo:
        raise _error(status.HTTP_400_BAD_REQUEST, "No tienes un grupo asignado")
    except TituloVacio:
        raise _error(status.HTTP_422_UNPROCESSABLE_CONTENT, "Escribe un título")
    except ComunicadoVacio:
        raise _error(status.HTTP_422_UNPROCESSABLE_CONTENT, "Escribe un texto o adjunta una imagen")
    except ExpiracionInvalida:
        raise _error(status.HTTP_422_UNPROCESSABLE_CONTENT, "La fecha de expiración debe ser posterior a hoy")
    except ImagenInvalida as error:
        raise _error(status.HTTP_422_UNPROCESSABLE_CONTENT, error.mensaje)
    except TecnicoAjeno:
        raise _error(status.HTTP_400_BAD_REQUEST, "El técnico no es de tu grupo")
    nombres = _Nombres(db)
    if comunicado.es_personal:
        _avisar_al_destinatario(comunicado, nombres, db)
    return a_comunicado_out(comunicado, nombres)


@router_comunicados.get("", response_model=list[ComunicadoOut])
def listar_comunicados_endpoint(db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(obtener_usuario_actual)):
    """El técnico ve los vigentes de su grupo y los dirigidos a él; el supervisor, los vigentes que escribió"""
    comunicados = listar_comunicados(actual.id, actual.rol, RepositorioComunicadosSQL(db), RepositorioSupervisoresSQL(db), RepositorioTecnicosSQL(db), datetime.now())
    nombres = _Nombres(db)
    return [a_comunicado_out(c, nombres) for c in comunicados]


@router_comunicados.delete("/{comunicado_id}", status_code=status.HTTP_204_NO_CONTENT)
def retirar_comunicado_endpoint(comunicado_id: UUID, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_supervisor)):
    try:
        retirar_comunicado(comunicado_id, actual.id, RepositorioComunicadosSQL(db), RepositorioSupervisoresSQL(db), _almacen(db))
    except ComunicadoNoEncontrado:
        raise _error(status.HTTP_404_NOT_FOUND, "Comunicado no encontrado")
    except NoEsElAutor:
        raise _error(status.HTTP_403_FORBIDDEN, "Solo quien escribió el comunicado puede retirarlo")
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router_comunicados.get("/{comunicado_id}/imagen")
def ver_imagen_endpoint(comunicado_id: UUID, db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(obtener_usuario_actual)):
    try:
        contenido, extension = obtener_imagen(
            comunicado_id, actual.id, actual.rol,
            RepositorioComunicadosSQL(db), RepositorioSupervisoresSQL(db), RepositorioTecnicosSQL(db), _almacen(db),
        )
    except ComunicadoNoEncontrado:
        raise _error(status.HTTP_404_NOT_FOUND, "Imagen no encontrada")
    # la imagen de un comunicado no cambia: el celular puede guardarla en caché
    return Response(content=contenido, media_type=TIPOS_IMAGEN[extension], headers={"Cache-Control": "private, max-age=86400"})
