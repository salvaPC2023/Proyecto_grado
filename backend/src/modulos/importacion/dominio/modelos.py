from dataclasses import dataclass, field


@dataclass
class FilaPersonal:
    fila: int  # número de fila en el Excel, para el reporte
    nombre_completo: str
    grupo_planificador: str
    supervisor: str


@dataclass
class FilaUbicacion:
    fila: int
    sector: str
    subsector: str
    sistema: str
    subsistema: str


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
    omitidos: list[Aviso] = field(default_factory=list)
    errores: list[Aviso] = field(default_factory=list)
