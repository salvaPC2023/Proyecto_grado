from datetime import time
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from src.compartido.bd import get_db
from ..dominio.modelos import Profesion
from .dependencias import UsuarioAutenticado, obtener_usuario_actual, requerir_administrador, requerir_supervisor
from .repositorio_grupos import RepositorioGruposSQL
from .repositorio_supervisores import RepositorioSupervisoresSQL
from .repositorio_tecnicos import RepositorioTecnicosSQL
from .repositorio_usuarios import RepositorioUsuariosSQL

from ..aplicacion.cambiar_estado_cuenta import TecnicoNoEncontrado, cambiar_estado_cuenta
from ..aplicacion.cambiar_estado_supervisor import SupervisorNoEncontrado, cambiar_estado_supervisor
from ..aplicacion.cambiar_password import ContrasenaActualIncorrecta, cambiar_password
from ..aplicacion.crear_supervisor import HorarioInvalido, crear_supervisor
from ..aplicacion.crear_tecnico import NombreUsuarioDuplicado, crear_tecnico
from ..aplicacion.editar_perfil import editar_perfil
from ..aplicacion.gestionar_grupos import GrupoNoEncontrado, asignar_supervisor, crear_grupo, listar_grupos
from ..aplicacion.iniciar_sesion import CredencialesInvalidas, CuentaDeshabilitada, iniciar_sesion
from ..aplicacion.listar_supervisores import listar_supervisores
from ..aplicacion.listar_tecnicos import listar_tecnicos
from ..aplicacion.ver_perfil import PerfilCompleto, ver_perfil


router_auth = APIRouter(prefix="/auth", tags=["autenticacion"])
router_tecnicos = APIRouter(prefix="/tecnicos", tags=["tecnicos"])
router_perfil = APIRouter(prefix="/perfil", tags=["perfil"])
router_supervisores = APIRouter(prefix="/supervisores", tags=["administracion"])
router_grupos = APIRouter(prefix="/grupos", tags=["administracion"])


class CredencialesLogin(BaseModel):
    nombre_usuario: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str

@router_auth.post("/login", response_model=TokenResponse)
def login(credenciales: CredencialesLogin, db: Session = Depends(get_db)):
    repositorio = RepositorioUsuariosSQL(db)
    try:
        resultado = iniciar_sesion(
            credenciales.nombre_usuario, credenciales.password, repositorio
        )
    except (CredencialesInvalidas, CuentaDeshabilitada):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
        )
    return TokenResponse(access_token=resultado.token, role=resultado.rol)

class CrearTecnicoRequest(BaseModel):
    nombre: str
    apellido_paterno: str
    apellido_materno: str | None = None
    nombre_usuario: str
    profesion: Profesion

class TecnicoOut(BaseModel):
    id: UUID
    usuario_id: UUID
    grupo_id: UUID
    profesion: Profesion
    nombre: str
    apellido_paterno: str
    apellido_materno: str | None
    nombre_usuario: str
    activo: bool

def a_tecnico_out(tecnico, repositorio_usuarios: RepositorioUsuariosSQL) -> TecnicoOut:
    usuario = repositorio_usuarios.obtener_por_id(tecnico.usuario_id)
    return TecnicoOut(
        id=tecnico.id,
        usuario_id=tecnico.usuario_id,
        grupo_id=tecnico.grupo_id,
        profesion=tecnico.profesion,
        nombre=usuario.nombre,
        apellido_paterno=usuario.apellido_paterno,
        apellido_materno=usuario.apellido_materno,
        nombre_usuario=usuario.nombre_usuario,
        activo=usuario.activo,
    )


@router_tecnicos.post("", response_model=TecnicoOut, status_code=status.HTTP_201_CREATED)
def crear_tecnico_endpoint(
    datos: CrearTecnicoRequest,
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_supervisor),
):
    repositorio_usuarios = RepositorioUsuariosSQL(db)
    repositorio_tecnicos = RepositorioTecnicosSQL(db)
    grupo_id = repositorio_tecnicos.obtener_grupo_del_supervisor(actual.id)
    if grupo_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El supervisor no tiene un grupo asignado",
        )
    try:
        tecnico = crear_tecnico(
            nombre=datos.nombre,
            apellido_paterno=datos.apellido_paterno,
            apellido_materno=datos.apellido_materno,
            nombre_usuario=datos.nombre_usuario,
            grupo_id=grupo_id,
            profesion=datos.profesion,
            creado_por_id=actual.id,
            repositorio_usuarios=repositorio_usuarios,
            repositorio_tecnicos=repositorio_tecnicos,
        )
    except NombreUsuarioDuplicado:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El nombre de usuario ya está en uso",
        )
    return a_tecnico_out(tecnico, repositorio_usuarios)


@router_tecnicos.get("", response_model=list[TecnicoOut])
def listar_tecnicos_endpoint(
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_supervisor),
):
    repositorio_usuarios = RepositorioUsuariosSQL(db)
    repositorio_tecnicos = RepositorioTecnicosSQL(db)
    tecnicos = listar_tecnicos(actual.id, repositorio_tecnicos)
    return [a_tecnico_out(t, repositorio_usuarios) for t in tecnicos]


class CambiarEstadoRequest(BaseModel):
    activo: bool


@router_tecnicos.patch("/{tecnico_id}/estado", status_code=status.HTTP_200_OK)
def cambiar_estado_endpoint(
    tecnico_id: UUID,
    datos: CambiarEstadoRequest,
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_supervisor),
):
    repositorio_usuarios = RepositorioUsuariosSQL(db)
    repositorio_tecnicos = RepositorioTecnicosSQL(db)
    try:
        cambiar_estado_cuenta(
            tecnico_id=tecnico_id,
            activo=datos.activo,
            supervisor_usuario_id=actual.id,
            repositorio_tecnicos=repositorio_tecnicos,
            repositorio_usuarios=repositorio_usuarios,
        )
    except TecnicoNoEncontrado:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Técnico no encontrado",
        )
    return {"activo": datos.activo}


class PerfilOut(BaseModel):
    id: UUID
    nombre: str
    apellido_paterno: str
    apellido_materno: str | None
    nombre_usuario: str


class EditarPerfilRequest(BaseModel):
    nombre: str
    apellido_paterno: str
    apellido_materno: str | None = None


class CambiarPasswordRequest(BaseModel):
    password_actual: str
    password_nueva: str


def a_perfil_out(usuario) -> PerfilOut:
    return PerfilOut(
        id=usuario.id,
        nombre=usuario.nombre,
        apellido_paterno=usuario.apellido_paterno,
        apellido_materno=usuario.apellido_materno,
        nombre_usuario=usuario.nombre_usuario,
    )


class PerfilCompletoOut(BaseModel):
    id: UUID
    nombre: str
    apellido_paterno: str
    apellido_materno: str | None
    nombre_usuario: str
    rol: str
    profesion: Profesion | None = None
    grupo_nombre: str | None = None
    horario_entrada: time | None = None
    horario_salida: time | None = None
    area_designada: str | None = None


def a_perfil_completo_out(perfil: PerfilCompleto) -> PerfilCompletoOut:
    return PerfilCompletoOut(
        id=perfil.usuario.id,
        nombre=perfil.usuario.nombre,
        apellido_paterno=perfil.usuario.apellido_paterno,
        apellido_materno=perfil.usuario.apellido_materno,
        nombre_usuario=perfil.usuario.nombre_usuario,
        rol=perfil.rol,
        profesion=perfil.profesion,
        grupo_nombre=perfil.grupo_nombre,
        horario_entrada=perfil.horario_entrada,
        horario_salida=perfil.horario_salida,
        area_designada=perfil.area_designada,
    )


@router_perfil.get("", response_model=PerfilCompletoOut)
def ver_perfil_endpoint(
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(obtener_usuario_actual),
):
    repositorio_usuarios = RepositorioUsuariosSQL(db)
    repositorio_tecnicos = RepositorioTecnicosSQL(db)
    repositorio_supervisores = RepositorioSupervisoresSQL(db)
    perfil = ver_perfil(
        actual.id,
        actual.rol,
        repositorio_usuarios,
        repositorio_tecnicos,
        repositorio_supervisores,
    )
    return a_perfil_completo_out(perfil)


@router_perfil.patch("", response_model=PerfilOut)
def editar_perfil_endpoint(
    datos: EditarPerfilRequest,
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(obtener_usuario_actual),
):
    repositorio = RepositorioUsuariosSQL(db)
    usuario = editar_perfil(
        actual.id,
        nombre=datos.nombre,
        apellido_paterno=datos.apellido_paterno,
        apellido_materno=datos.apellido_materno,
        repositorio=repositorio,
    )
    return a_perfil_out(usuario)


@router_perfil.patch("/password", status_code=status.HTTP_200_OK)
def cambiar_password_endpoint(
    datos: CambiarPasswordRequest,
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(obtener_usuario_actual),
):
    repositorio = RepositorioUsuariosSQL(db)
    try:
        cambiar_password(
            actual.id,
            password_actual=datos.password_actual,
            password_nueva=datos.password_nueva,
            repositorio=repositorio,
        )
    except ContrasenaActualIncorrecta:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="La contraseña actual es incorrecta",
        )
    return {"detail": "Contraseña actualizada"}


class CrearSupervisorRequest(BaseModel):
    nombre: str
    apellido_paterno: str
    apellido_materno: str | None = None
    nombre_usuario: str
    nombre_de_grupo: str
    horario_entrada: time
    horario_salida: time
    area_designada: str | None = None


class SupervisorOut(BaseModel):
    id: UUID
    usuario_id: UUID
    nombre: str
    apellido_paterno: str
    apellido_materno: str | None
    nombre_usuario: str
    activo: bool
    horario_entrada: time
    horario_salida: time
    area_designada: str | None
    grupo_nombre: str | None


def a_supervisor_out(supervisor, repositorio_usuarios: RepositorioUsuariosSQL, repositorio_supervisores: RepositorioSupervisoresSQL) -> SupervisorOut:
    usuario = repositorio_usuarios.obtener_por_id(supervisor.usuario_id)
    grupo = repositorio_supervisores.obtener_grupo(supervisor.id)
    return SupervisorOut(
        id=supervisor.id,
        usuario_id=supervisor.usuario_id,
        nombre=usuario.nombre,
        apellido_paterno=usuario.apellido_paterno,
        apellido_materno=usuario.apellido_materno,
        nombre_usuario=usuario.nombre_usuario,
        activo=usuario.activo,
        horario_entrada=supervisor.horario_entrada,
        horario_salida=supervisor.horario_salida,
        area_designada=supervisor.area_designada,
        grupo_nombre=grupo.nombre_de_grupo if grupo else None,
    )


@router_supervisores.get("", response_model=list[SupervisorOut])
def listar_supervisores_endpoint(
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_administrador),
):
    repositorio_usuarios = RepositorioUsuariosSQL(db)
    repositorio_supervisores = RepositorioSupervisoresSQL(db)
    supervisores = listar_supervisores(repositorio_supervisores)
    return [a_supervisor_out(s, repositorio_usuarios, repositorio_supervisores) for s in supervisores]


@router_supervisores.post("", response_model=SupervisorOut, status_code=status.HTTP_201_CREATED)
def crear_supervisor_endpoint(
    datos: CrearSupervisorRequest,
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_administrador),
):
    repositorio_usuarios = RepositorioUsuariosSQL(db)
    repositorio_supervisores = RepositorioSupervisoresSQL(db)
    try:
        supervisor = crear_supervisor(
            nombre=datos.nombre,
            apellido_paterno=datos.apellido_paterno,
            apellido_materno=datos.apellido_materno,
            nombre_usuario=datos.nombre_usuario,
            nombre_de_grupo=datos.nombre_de_grupo,
            horario_entrada=datos.horario_entrada,
            horario_salida=datos.horario_salida,
            area_designada=datos.area_designada,
            repositorio_usuarios=repositorio_usuarios,
            repositorio_supervisores=repositorio_supervisores,
        )
    except NombreUsuarioDuplicado:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El nombre de usuario ya está en uso",
        )
    except HorarioInvalido:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="La hora de entrada y la de salida no pueden ser iguales",
        )
    return a_supervisor_out(supervisor, repositorio_usuarios, repositorio_supervisores)


@router_supervisores.patch("/{supervisor_id}/estado", status_code=status.HTTP_200_OK)
def cambiar_estado_supervisor_endpoint(
    supervisor_id: UUID,
    datos: CambiarEstadoRequest,
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_administrador),
):
    try:
        cambiar_estado_supervisor(
            supervisor_id=supervisor_id,
            activo=datos.activo,
            repositorio_supervisores=RepositorioSupervisoresSQL(db),
            repositorio_usuarios=RepositorioUsuariosSQL(db),
        )
    except SupervisorNoEncontrado:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Supervisor no encontrado",
        )
    return {"activo": datos.activo}


class GrupoOut(BaseModel):
    id: UUID
    nombre_de_grupo: str
    supervisor_id: UUID | None
    supervisor_nombre: str | None
    horario_entrada: time
    horario_salida: time
    cantidad_tecnicos: int


class CrearGrupoRequest(BaseModel):
    nombre_de_grupo: str = Field(min_length=1, max_length=100)
    supervisor_id: UUID


class AsignarSupervisorRequest(BaseModel):
    supervisor_id: UUID


def a_grupo_out(grupo, repositorio_grupos: RepositorioGruposSQL, repositorio_supervisores: RepositorioSupervisoresSQL, repositorio_usuarios: RepositorioUsuariosSQL) -> GrupoOut:
    supervisor_nombre = None
    if grupo.supervisor_id is not None:
        supervisor = repositorio_supervisores.obtener_por_id(grupo.supervisor_id)
        usuario = repositorio_usuarios.obtener_por_id(supervisor.usuario_id)
        supervisor_nombre = f"{usuario.nombre} {usuario.apellido_paterno}"
    return GrupoOut(
        id=grupo.id,
        nombre_de_grupo=grupo.nombre_de_grupo,
        supervisor_id=grupo.supervisor_id,
        supervisor_nombre=supervisor_nombre,
        horario_entrada=grupo.horario_entrada,
        horario_salida=grupo.horario_salida,
        cantidad_tecnicos=repositorio_grupos.contar_tecnicos(grupo.id),
    )


@router_grupos.get("", response_model=list[GrupoOut])
def listar_grupos_endpoint(
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_administrador),
):
    repositorio_grupos = RepositorioGruposSQL(db)
    repositorio_supervisores = RepositorioSupervisoresSQL(db)
    repositorio_usuarios = RepositorioUsuariosSQL(db)
    return [a_grupo_out(g, repositorio_grupos, repositorio_supervisores, repositorio_usuarios) for g in listar_grupos(repositorio_grupos)]


@router_grupos.post("", response_model=GrupoOut, status_code=status.HTTP_201_CREATED)
def crear_grupo_endpoint(
    datos: CrearGrupoRequest,
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_administrador),
):
    repositorio_grupos = RepositorioGruposSQL(db)
    repositorio_supervisores = RepositorioSupervisoresSQL(db)
    try:
        grupo = crear_grupo(datos.nombre_de_grupo.strip(), datos.supervisor_id, repositorio_grupos, repositorio_supervisores)
    except SupervisorNoEncontrado:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Supervisor no encontrado")
    return a_grupo_out(grupo, repositorio_grupos, repositorio_supervisores, RepositorioUsuariosSQL(db))


@router_grupos.patch("/{grupo_id}/supervisor", status_code=status.HTTP_200_OK)
def asignar_supervisor_endpoint(
    grupo_id: UUID,
    datos: AsignarSupervisorRequest,
    db: Session = Depends(get_db),
    actual: UsuarioAutenticado = Depends(requerir_administrador),
):
    try:
        asignar_supervisor(grupo_id, datos.supervisor_id, RepositorioGruposSQL(db), RepositorioSupervisoresSQL(db))
    except GrupoNoEncontrado:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Grupo no encontrado")
    except SupervisorNoEncontrado:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Supervisor no encontrado")
    return {"detail": "Supervisor asignado"}
