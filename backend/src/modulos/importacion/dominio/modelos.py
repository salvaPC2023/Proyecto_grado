from dataclasses import dataclass, field


@dataclass
class FilaPersonal:
    fila: int  # número de fila en el Excel, para el reporte
    nombre_completo: str
    grupo_planificador: str
    supervisor: str


@dataclass
class FilaGrupo:
    fila: int
    grupo: str
    turno: str
    supervisor: str


@dataclass
class FilaUbicacion:
    fila: int
    sector: str
    subsector: str
    sistema: str
    subsistema: str


@dataclass
class FilaOT:
    """Una fila por paso; las filas con el mismo número de OT forman una sola orden"""
    fila: int
    ot: str
    titulo: str
    tipo: str
    ubicacion: str  # los niveles separados por " / ", como se muestran en la app y en el Excel exportado
    tecnico: str
    prioridad: str
    inicio: str
    fin: str
    equipo_en_funcionamiento: str
    clave: str
    descripcion_paso: str
    horas: str


@dataclass
class Aviso:
    fila: int
    dato: str
    motivo: str


@dataclass
class UsuarioCreado:
    fila: int
    nombre_completo: str
    nombre_usuario: str
    rol: str


@dataclass
class ResultadoImportacion:
    usuarios_creados: list[UsuarioCreado] = field(default_factory=list)
    ubicaciones_creadas: int = 0
    ots_creadas: int = 0
    omitidos: list[Aviso] = field(default_factory=list)
    errores: list[Aviso] = field(default_factory=list)
