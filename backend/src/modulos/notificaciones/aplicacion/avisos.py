from uuid import UUID

from ..dominio.modelos import Notificacion
from ..dominio.puertos import RepositorioDispositivos, ServicioNotificaciones


def avisar(aviso: Notificacion, repositorio_dispositivos: RepositorioDispositivos, servicio: ServicioNotificaciones) -> bool:
    """Envía el aviso a todos los celulares del usuario y olvida los que ya no sirven.
    False si el usuario no tiene ningún celular registrado (nunca abrió la app o cerró sesión)"""
    tokens = repositorio_dispositivos.tokens_de(aviso.usuario_id)
    if not tokens:
        return False
    invalidos = servicio.enviar(tokens, aviso.titulo, aviso.cuerpo)
    if invalidos:
        repositorio_dispositivos.eliminar(invalidos)
    return True


def aviso_de_comunicado_personal(tecnico_usuario_id: UUID, autor: str, titulo: str) -> Notificacion:
    """Solo los comunicados personales se notifican: los generales del grupo se ven en el tablón del inicio"""
    return Notificacion(tecnico_usuario_id, "Comunicado personal", f"{autor}: {titulo}" if autor else titulo)
