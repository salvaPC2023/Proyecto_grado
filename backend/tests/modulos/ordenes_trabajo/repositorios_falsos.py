from src.modulos.acceso_roles.dominio.modelos import Tecnico
from src.modulos.acceso_roles.dominio.puertos import RepositorioSupervisores, RepositorioTecnicos
from src.modulos.ordenes_trabajo.dominio.puertos import RepositorioOrdenesTrabajo
from src.modulos.ubicaciones_tecnicas.dominio.puertos import RepositorioUbicacionesTecnicas

# Implementaciones en memoria, no se llama a la base de datos real

class RepositorioOrdenesTrabajoFalso(RepositorioOrdenesTrabajo):
    def __init__(self, grupo_de_tecnico: dict | None = None):
        self.ots = {}
        self._grupo_de_tecnico = grupo_de_tecnico or {}
        self.fecha_recibida = None

    def crear(self, ot):
        self.ots[ot.id] = ot
        return ot

    def obtener_por_id(self, id):
        return self.ots.get(id)

    def listar_por_tecnico(self, tecnico_id, fecha=None):
        self.fecha_recibida = fecha
        return [ot for ot in self.ots.values() if ot.tecnico_asignado_id == tecnico_id]

    def listar_por_grupo(self, grupo_id, fecha=None):
        self.fecha_recibida = fecha
        return [ot for ot in self.ots.values() if self._grupo_de_tecnico.get(ot.tecnico_asignado_id) == grupo_id]


class RepositorioUbicacionesFalso(RepositorioUbicacionesTecnicas):
    def __init__(self, ubicaciones):
        self._ubicaciones = ubicaciones

    def listar_ubicaciones(self):
        return list(self._ubicaciones)

    def obtener_por_id(self, id):
        return next((u for u in self._ubicaciones if u.id == id), None)


class RepositorioTecnicosFalso(RepositorioTecnicos):
    def __init__(self, supervisor_de_tecnico: dict | None = None, tecnicos: list[Tecnico] | None = None, grupo_de_supervisor: dict | None = None):
        self._supervisor_de_tecnico = supervisor_de_tecnico or {}
        self._tecnicos = tecnicos or []
        self._grupo_de_supervisor = grupo_de_supervisor or {}

    def pertenece_a_supervisor(self, tecnico_id, supervisor_usuario_id):
        return self._supervisor_de_tecnico.get(tecnico_id) == supervisor_usuario_id

    def obtener_por_usuario_id(self, usuario_id):
        return next((t for t in self._tecnicos if t.usuario_id == usuario_id), None)

    def obtener_grupo_del_supervisor(self, supervisor_usuario_id):
        return self._grupo_de_supervisor.get(supervisor_usuario_id)

    def obtener_por_id(self, id): raise NotImplementedError
    def crear(self, tecnico): raise NotImplementedError
    def listar_por_supervisor(self, supervisor_usuario_id): raise NotImplementedError
    def obtener_nombre_grupo(self, grupo_id): raise NotImplementedError


class RepositorioSupervisoresFalso(RepositorioSupervisores):
    def __init__(self, supervisores=None):
        self._supervisores = supervisores or []

    def obtener_por_usuario_id(self, usuario_id):
        return next((s for s in self._supervisores if s.usuario_id == usuario_id), None)
