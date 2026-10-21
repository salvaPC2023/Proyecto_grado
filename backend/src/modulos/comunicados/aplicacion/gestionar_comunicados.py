from datetime import datetime
from uuid import UUID, uuid4

from src.modulos.acceso_roles.dominio.puertos import RepositorioSupervisores, RepositorioTecnicos, Rol

from ..dominio.imagenes import TAMANO_MAXIMO, extension_de_imagen
from ..dominio.modelos import Categoria, Comunicado
from ..dominio.puertos import AlmacenImagenes, RepositorioComunicados


class SupervisorSinGrupo(Exception):
    pass


class TituloVacio(Exception):
    pass


class ComunicadoVacio(Exception):
    """No tiene texto ni imagen"""


class ExpiracionInvalida(Exception):
    """La fecha de expiración no es posterior al envío"""


class ImagenInvalida(Exception):
    def __init__(self, mensaje: str):
        super().__init__(mensaje)
        self.mensaje = mensaje


class TecnicoAjeno(Exception):
    """El destinatario no es un técnico del grupo del supervisor"""


class ComunicadoNoEncontrado(Exception):
    pass


class NoEsElAutor(Exception):
    pass


def publicar_comunicado(
    supervisor_usuario_id: UUID,
    titulo: str,
    categoria: Categoria,
    fecha_expiracion: datetime,
    repositorio_comunicados: RepositorioComunicados,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_tecnicos: RepositorioTecnicos,
    almacen_imagenes: AlmacenImagenes,
    ahora: datetime,
    texto: str | None = None,
    imagen: bytes | None = None,
    tecnico_id: UUID | None = None,
) -> Comunicado:
    """Comunicado general para el grupo del supervisor, o personal si indica un técnico del grupo"""
    grupo_id = repositorio_tecnicos.obtener_grupo_del_supervisor(supervisor_usuario_id)
    supervisor = repositorio_supervisores.obtener_por_usuario_id(supervisor_usuario_id)
    if grupo_id is None or supervisor is None:
        raise SupervisorSinGrupo()

    titulo = titulo.strip()
    texto = (texto or "").strip() or None
    if not titulo:
        raise TituloVacio()
    if texto is None and not imagen:
        raise ComunicadoVacio()
    if fecha_expiracion <= ahora:
        raise ExpiracionInvalida()
    if tecnico_id is not None and not repositorio_tecnicos.pertenece_a_supervisor(tecnico_id, supervisor_usuario_id):
        raise TecnicoAjeno()

    nombre_imagen = None
    if imagen:
        extension = extension_de_imagen(imagen)
        if extension is None:
            raise ImagenInvalida("La imagen debe ser JPG o PNG")
        if len(imagen) > TAMANO_MAXIMO:
            raise ImagenInvalida("La imagen no puede pasar de 2 MB")
        nombre_imagen = almacen_imagenes.guardar(imagen, extension)

    return repositorio_comunicados.crear(Comunicado(
        id=uuid4(),
        grupo_id=grupo_id,
        supervisor_id=supervisor.id,
        titulo=titulo,
        categoria=categoria,
        fecha_envio=ahora,
        fecha_expiracion=fecha_expiracion,
        texto=texto,
        imagen=nombre_imagen,
        tecnico_id=tecnico_id,
    ))


def listar_comunicados(
    usuario_id: UUID,
    rol: Rol,
    repositorio_comunicados: RepositorioComunicados,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_tecnicos: RepositorioTecnicos,
    ahora: datetime,
) -> list[Comunicado]:
    """El técnico ve los vigentes de su grupo y los dirigidos a él; el supervisor, los vigentes que escribió"""
    if rol == "tecnico":
        tecnico = repositorio_tecnicos.obtener_por_usuario_id(usuario_id)
        if tecnico is None:
            return []
        return repositorio_comunicados.listar_vigentes_para_tecnico(tecnico.grupo_id, tecnico.id, ahora)
    if rol == "supervisor":
        supervisor = repositorio_supervisores.obtener_por_usuario_id(usuario_id)
        if supervisor is None:
            return []
        return repositorio_comunicados.listar_vigentes_de_supervisor(supervisor.id, ahora)
    return []


def retirar_comunicado(
    comunicado_id: UUID,
    supervisor_usuario_id: UUID,
    repositorio_comunicados: RepositorioComunicados,
    repositorio_supervisores: RepositorioSupervisores,
    almacen_imagenes: AlmacenImagenes,
) -> None:
    """Solo lo retira quien lo escribió; también se borra su imagen"""
    comunicado = repositorio_comunicados.obtener_por_id(comunicado_id)
    if comunicado is None:
        raise ComunicadoNoEncontrado()
    supervisor = repositorio_supervisores.obtener_por_usuario_id(supervisor_usuario_id)
    if supervisor is None or comunicado.supervisor_id != supervisor.id:
        raise NoEsElAutor()

    repositorio_comunicados.eliminar(comunicado_id)
    if comunicado.imagen:
        almacen_imagenes.eliminar(comunicado.imagen)


def obtener_imagen(
    comunicado_id: UUID,
    usuario_id: UUID,
    rol: Rol,
    repositorio_comunicados: RepositorioComunicados,
    repositorio_supervisores: RepositorioSupervisores,
    repositorio_tecnicos: RepositorioTecnicos,
    almacen_imagenes: AlmacenImagenes,
) -> tuple[bytes, str]:
    """La imagen y su extensión, solo para quien puede ver el comunicado"""
    comunicado = repositorio_comunicados.obtener_por_id(comunicado_id)
    if comunicado is None or comunicado.imagen is None or not _puede_verlo(comunicado, usuario_id, rol, repositorio_supervisores, repositorio_tecnicos):
        raise ComunicadoNoEncontrado()  # no se distingue "no existe" de "no es tuyo"
    contenido = almacen_imagenes.leer(comunicado.imagen)
    if contenido is None:
        raise ComunicadoNoEncontrado()
    return contenido, comunicado.imagen.rsplit(".", 1)[-1]


def _puede_verlo(comunicado: Comunicado, usuario_id: UUID, rol: Rol, repositorio_supervisores: RepositorioSupervisores, repositorio_tecnicos: RepositorioTecnicos) -> bool:
    if rol == "tecnico":
        tecnico = repositorio_tecnicos.obtener_por_usuario_id(usuario_id)
        return tecnico is not None and comunicado.grupo_id == tecnico.grupo_id and comunicado.tecnico_id in (None, tecnico.id)
    if rol == "supervisor":
        supervisor = repositorio_supervisores.obtener_por_usuario_id(usuario_id)
        return supervisor is not None and comunicado.supervisor_id == supervisor.id
    return False
