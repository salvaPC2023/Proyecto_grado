from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from src.compartido.bd import get_db
from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, requerir_administrador, requerir_supervisor
from src.modulos.acceso_roles.infraestructura.repositorio_supervisores import RepositorioSupervisoresSQL
from src.modulos.acceso_roles.infraestructura.repositorio_tecnicos import RepositorioTecnicosSQL
from src.modulos.acceso_roles.infraestructura.repositorio_usuarios import RepositorioUsuariosSQL
from src.modulos.ordenes_trabajo.infraestructura.repositorio_ordenes_trabajo import RepositorioOrdenesTrabajoSQL
from src.modulos.ubicaciones_tecnicas.infraestructura.repositorio_ubicaciones_tecnicas import RepositorioUbicacionesTecnicasSQL

from ..aplicacion.importar import SupervisorSinGrupo, importar_carga_inicial, importar_para_mi_grupo
from ..dominio.modelos import ResultadoImportacion
from ..dominio.puertos import PlantillaInvalida
from .consulta_personal_sql import ConsultaPersonalSQL
from .lector_excel import leer_ots, leer_plantilla

router_importacion = APIRouter(prefix="/importacion", tags=["importacion"])

TAMANO_MAXIMO = 5 * 1024 * 1024  # 5 MB


class AvisoOut(BaseModel):
    fila: int
    dato: str
    motivo: str


class UsuarioCreadoOut(BaseModel):
    fila: int
    nombre_completo: str
    nombre_usuario: str
    rol: str


class ResultadoOut(BaseModel):
    usuarios_creados: list[UsuarioCreadoOut]
    ubicaciones_creadas: int
    ots_creadas: int
    omitidos: list[AvisoOut]
    errores: list[AvisoOut]


def a_resultado_out(resultado: ResultadoImportacion) -> ResultadoOut:
    return ResultadoOut(
        usuarios_creados=[UsuarioCreadoOut(**vars(u)) for u in resultado.usuarios_creados],
        ubicaciones_creadas=resultado.ubicaciones_creadas,
        ots_creadas=resultado.ots_creadas,
        omitidos=[AvisoOut(**vars(a)) for a in resultado.omitidos],
        errores=[AvisoOut(**vars(a)) for a in resultado.errores],
    )


async def _leer(archivo: UploadFile):
    contenido = await archivo.read(TAMANO_MAXIMO + 1)
    if len(contenido) > TAMANO_MAXIMO:
        raise HTTPException(status_code=status.HTTP_413_CONTENT_TOO_LARGE, detail="El archivo no puede pasar de 5 MB")
    try:
        return *leer_plantilla(contenido), leer_ots(contenido)
    except PlantillaInvalida as error:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=error.mensaje)


@router_importacion.post("/carga-inicial", response_model=ResultadoOut)
async def importar_carga_inicial_endpoint(archivo: UploadFile = File(...), db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_administrador)):
    # la tabla de órdenes de trabajo es solo para el supervisor: el administrador no gestiona OT
    personal, ubicaciones, grupos, _ = await _leer(archivo)
    try:
        resultado = importar_carga_inicial(
            personal, ubicaciones, actual.id, ConsultaPersonalSQL(db),
            RepositorioUsuariosSQL(db), RepositorioSupervisoresSQL(db), RepositorioTecnicosSQL(db), RepositorioUbicacionesTecnicasSQL(db),
            grupos=grupos,
        )
    except PlantillaInvalida as error:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=error.mensaje)
    return a_resultado_out(resultado)


@router_importacion.post("/mi-grupo", response_model=ResultadoOut)
async def importar_para_mi_grupo_endpoint(archivo: UploadFile = File(...), db: Session = Depends(get_db), actual: UsuarioAutenticado = Depends(requerir_supervisor)):
    # la tabla de Grupos es solo para la carga inicial del administrador
    personal, ubicaciones, _, ots = await _leer(archivo)
    try:
        resultado = importar_para_mi_grupo(
            personal, ubicaciones, actual.id, ConsultaPersonalSQL(db),
            RepositorioUsuariosSQL(db), RepositorioSupervisoresSQL(db), RepositorioTecnicosSQL(db), RepositorioUbicacionesTecnicasSQL(db),
            ots=ots, repositorio_ots=RepositorioOrdenesTrabajoSQL(db),
        )
    except PlantillaInvalida as error:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=error.mensaje)
    except SupervisorSinGrupo:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No tienes un grupo asignado")
    return a_resultado_out(resultado)
