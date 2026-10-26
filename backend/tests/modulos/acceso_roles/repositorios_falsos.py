from datetime import time
from uuid import uuid4

from src.compartido.seguridad import hashear_password
from src.modulos.acceso_roles.dominio.modelos import Supervisor, Tecnico, Usuario
from src.modulos.acceso_roles.dominio.puertos import GrupoEnUso, RepositorioGrupos, RepositorioSupervisores, RepositorioTecnicos, RepositorioUsuarios

# Implementaciones en memoria, no se llama a la base de datos real


def crear_usuario(nombre_usuario="tecnico01", password="clave123", activo=True):
    return Usuario(
        id=uuid4(),
        nombre="Juan",
        apellido_paterno="Perez",
        nombre_usuario=nombre_usuario,
        password_hash=hashear_password(password),
        activo=activo,
        debe_cambiar_password=False,
    )


def crear_supervisor(usuario_id):
    return Supervisor(id=uuid4(), usuario_id=usuario_id, horario_entrada=time(8), horario_salida=time(17), area_designada="Embotellado")


class RepositorioUsuariosFalso(RepositorioUsuarios):
    def __init__(self, usuarios=None, rol="tecnico"):
        self.usuarios = {u.nombre_usuario: u for u in usuarios or []}
        self._rol = rol

    def obtener_por_nombre_usuario(self, nombre_usuario):
        return self.usuarios.get(nombre_usuario)

    def obtener_por_id(self, id):
        return next((u for u in self.usuarios.values() if u.id == id), None)

    def obtener_rol(self, usuario_id):
        return self._rol

    def existe_administrador(self):
        return any(u.rol == "admin" for u in self.usuarios.values())

    def crear(self, usuario):
        self.usuarios[usuario.nombre_usuario] = usuario
        return usuario

    def actualizar(self, usuario):
        # si cambió el nombre de usuario, se quita la entrada con el nombre anterior
        self.usuarios = {nombre: u for nombre, u in self.usuarios.items() if u.id != usuario.id}
        self.usuarios[usuario.nombre_usuario] = usuario
        return usuario


class RepositorioTecnicosFalso(RepositorioTecnicos):
    def __init__(self, tecnicos=None, supervisor_de_tecnico=None, nombre_de_grupo=None):
        self.tecnicos = list(tecnicos or [])
        self._supervisor_de_tecnico = supervisor_de_tecnico or {}
        self._nombre_de_grupo = nombre_de_grupo or {}

    def obtener_por_id(self, id):
        return next((t for t in self.tecnicos if t.id == id), None)

    def obtener_por_usuario_id(self, usuario_id):
        return next((t for t in self.tecnicos if t.usuario_id == usuario_id), None)

    def crear(self, tecnico):
        self.tecnicos.append(tecnico)
        return tecnico

    def listar_por_supervisor(self, supervisor_usuario_id):
        return [t for t in self.tecnicos if self._supervisor_de_tecnico.get(t.id) == supervisor_usuario_id]

    def listar_por_grupo(self, grupo_id):
        return [t for t in self.tecnicos if t.grupo_id == grupo_id]

    def pertenece_a_supervisor(self, tecnico_id, supervisor_usuario_id):
        return self._supervisor_de_tecnico.get(tecnico_id) == supervisor_usuario_id

    def obtener_nombre_grupo(self, grupo_id):
        return self._nombre_de_grupo.get(grupo_id)

    def obtener_grupo_del_supervisor(self, supervisor_usuario_id):
        return None


class RepositorioSupervisoresFalso(RepositorioSupervisores):
    def __init__(self, supervisores=None, repositorio_grupos=None):
        self.supervisores = list(supervisores or [])
        self.grupos = {}  # supervisor_id -> grupo, si no se comparte un RepositorioGruposFalso
        self._repositorio_grupos = repositorio_grupos

    def obtener_por_usuario_id(self, usuario_id):
        return next((s for s in self.supervisores if s.usuario_id == usuario_id), None)

    def obtener_por_id(self, id):
        return next((s for s in self.supervisores if s.id == id), None)

    def crear(self, supervisor, grupo):
        self.supervisores.append(supervisor)
        self.grupos[supervisor.id] = grupo
        return supervisor

    def listar(self):
        return list(self.supervisores)

    def obtener_grupo(self, supervisor_id):
        if self._repositorio_grupos is not None:
            return next((g for g in self._repositorio_grupos.listar() if g.supervisor_id == supervisor_id), None)
        return self.grupos.get(supervisor_id)

    def actualizar(self, supervisor):
        grupo = self.obtener_grupo(supervisor.id)
        if grupo is not None:
            grupo.horario_entrada = supervisor.horario_entrada
            grupo.horario_salida = supervisor.horario_salida
        return supervisor


class RepositorioGruposFalso(RepositorioGrupos):
    """Los grupos en memoria; usa el repositorio de supervisores para copiar su horario al asignarlos"""

    def __init__(self, grupos=None, tecnicos_por_grupo=None, con_comunicados=()):
        self.grupos = {g.id: g for g in grupos or []}
        self._tecnicos_por_grupo = tecnicos_por_grupo or {}
        self._con_comunicados = set(con_comunicados)
        self.repositorio_supervisores = None

    def listar(self):
        return list(self.grupos.values())

    def obtener_por_id(self, id):
        return self.grupos.get(id)

    def crear(self, grupo):
        self.grupos[grupo.id] = grupo
        return grupo

    def asignar_supervisores(self, asignaciones):
        for grupo_id, supervisor_id in asignaciones.items():
            grupo = self.grupos[grupo_id]
            grupo.supervisor_id = supervisor_id
            if supervisor_id is not None and self.repositorio_supervisores is not None:
                supervisor = self.repositorio_supervisores.obtener_por_id(supervisor_id)
                grupo.horario_entrada = supervisor.horario_entrada
                grupo.horario_salida = supervisor.horario_salida

    def contar_tecnicos(self, grupo_id):
        return self._tecnicos_por_grupo.get(grupo_id, 0)

    def eliminar(self, id):
        if id in self._con_comunicados:
            raise GrupoEnUso()
        del self.grupos[id]


def repositorios_de_grupos(supervisores, grupos, **opciones):
    """Supervisores y grupos que comparten los mismos datos, como en la base real"""
    repositorio_grupos = RepositorioGruposFalso(grupos, **opciones)
    repositorio_supervisores = RepositorioSupervisoresFalso(supervisores, repositorio_grupos=repositorio_grupos)
    repositorio_grupos.repositorio_supervisores = repositorio_supervisores
    return repositorio_supervisores, repositorio_grupos


def crear_tecnico_de(usuario, profesion="mecanico", grupo_id=None):
    return Tecnico(id=uuid4(), usuario_id=usuario.id, grupo_id=grupo_id or uuid4(), profesion=profesion)
