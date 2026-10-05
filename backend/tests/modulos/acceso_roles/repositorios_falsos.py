from datetime import time
from uuid import uuid4

from src.compartido.seguridad import hashear_password
from src.modulos.acceso_roles.dominio.modelos import Supervisor, Tecnico, Usuario
from src.modulos.acceso_roles.dominio.puertos import RepositorioSupervisores, RepositorioTecnicos, RepositorioUsuarios

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

    def crear(self, usuario):
        self.usuarios[usuario.nombre_usuario] = usuario
        return usuario

    def actualizar(self, usuario):
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

    def pertenece_a_supervisor(self, tecnico_id, supervisor_usuario_id):
        return self._supervisor_de_tecnico.get(tecnico_id) == supervisor_usuario_id

    def obtener_nombre_grupo(self, grupo_id):
        return self._nombre_de_grupo.get(grupo_id)

    def obtener_grupo_del_supervisor(self, supervisor_usuario_id):
        return None


class RepositorioSupervisoresFalso(RepositorioSupervisores):
    def __init__(self, supervisores=None):
        self._supervisores = supervisores or []

    def obtener_por_usuario_id(self, usuario_id):
        return next((s for s in self._supervisores if s.usuario_id == usuario_id), None)


def crear_tecnico_de(usuario, profesion="mecanico", grupo_id=None):
    return Tecnico(id=uuid4(), usuario_id=usuario.id, grupo_id=grupo_id or uuid4(), profesion=profesion)
