from dataclasses import dataclass
from datetime import time
from uuid import UUID

from ..dominio.modelos import Profesion, Usuario
from ..dominio.puertos import RepositorioSupervisores, RepositorioTecnicos, RepositorioUsuarios, Rol


@dataclass
class PerfilCompleto:
    usuario: Usuario
    rol: Rol
    profesion: Profesion | None = None
    grupo_nombre: str | None = None
    horario_entrada: time | None = None
    horario_salida: time | None = None
    area_designada: str | None = None


def ver_perfil(
    usuario_id: UUID,
    rol: Rol,
    repositorio_usuarios: RepositorioUsuarios,
    repositorio_tecnicos: RepositorioTecnicos,
    repositorio_supervisores: RepositorioSupervisores,
) -> PerfilCompleto:
    usuario = repositorio_usuarios.obtener_por_id(usuario_id)
    if usuario is None:
        raise ValueError(f"Usuario {usuario_id} no encontrado")

    if rol == "tecnico":
        tecnico = repositorio_tecnicos.obtener_por_usuario_id(usuario_id)
        grupo_nombre = (
            repositorio_tecnicos.obtener_nombre_grupo(tecnico.grupo_id)
            if tecnico
            else None
        )
        return PerfilCompleto(
            usuario=usuario,
            rol=rol,
            profesion=tecnico.profesion if tecnico else None,
            grupo_nombre=grupo_nombre,
        )

    supervisor = repositorio_supervisores.obtener_por_usuario_id(usuario_id)
    grupo = repositorio_supervisores.obtener_grupo(supervisor.id) if supervisor else None
    return PerfilCompleto(
        usuario=usuario,
        rol=rol,
        grupo_nombre=grupo.nombre_de_grupo if grupo else None,
        horario_entrada=supervisor.horario_entrada if supervisor else None,
        horario_salida=supervisor.horario_salida if supervisor else None,
        area_designada=supervisor.area_designada if supervisor else None,
    )
