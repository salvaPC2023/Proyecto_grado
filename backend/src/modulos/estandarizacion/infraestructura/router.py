from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from src.modulos.acceso_roles.infraestructura.dependencias import UsuarioAutenticado, requerir_tecnico

from ..aplicacion.estandarizar_descripcion import DescripcionVacia, estandarizar_descripcion
from ..dominio.puertos import ServicioNoDisponible, TiempoAgotado
from .servicio_openai import ServicioEstandarizacionOpenAI

router_descripciones = APIRouter(prefix="/descripciones", tags=["estandarizacion"])


class EstandarizarRequest(BaseModel):
    texto: str = Field(min_length=1, max_length=2000)


class EstandarizarResponse(BaseModel):
    texto_estandarizado: str


@router_descripciones.post("/estandarizar", response_model=EstandarizarResponse)
def estandarizar_endpoint(datos: EstandarizarRequest, actual: UsuarioAutenticado = Depends(requerir_tecnico)):
    try:
        texto = estandarizar_descripcion(datos.texto, ServicioEstandarizacionOpenAI())
    except DescripcionVacia:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="Escribe la descripción antes de estandarizarla")
    except TiempoAgotado:
        raise HTTPException(status_code=status.HTTP_504_GATEWAY_TIMEOUT, detail="No se pudo estandarizar. Puedes continuar con tu texto original")
    except ServicioNoDisponible:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="No se pudo estandarizar. Puedes continuar con tu texto original")
    return EstandarizarResponse(texto_estandarizado=texto)
