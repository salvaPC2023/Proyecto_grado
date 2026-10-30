from datetime import datetime, timedelta

import pytest

from src.modulos.estandarizacion.dominio.puertos import ServicioEstandarizacion
from src.modulos.estandarizacion.infraestructura import router as router_estandarizacion

pytestmark = pytest.mark.integracion

# basta con la firma de un PNG: el backend reconoce la imagen por sus primeros bytes
IMAGEN_PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 64


@pytest.fixture
def grupo(api):
    _, supervisor = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    carlos, sesion_carlos = api.crear_tecnico(supervisor, "Carlos", "Mamani")
    _, sesion_luis = api.crear_tecnico(supervisor, "Luis", "Torrez")
    return {"supervisor": supervisor, "carlos": carlos, "sesion_carlos": sesion_carlos, "sesion_luis": sesion_luis}


def publicar(api, supervisor, titulo, tecnico_id=None, imagen=None):
    datos = {
        "titulo": titulo, "categoria": "seguridad", "texto": "Usar EPP completo",
        "fecha_expiracion": (datetime.now() + timedelta(days=3)).isoformat(),
    }
    if tecnico_id:
        datos["tecnico_id"] = tecnico_id
    archivos = {"imagen": ("aviso.png", imagen, "image/png")} if imagen else None
    respuesta = api.cliente.post("/api/v1/comunicados", headers=supervisor, data=datos, files=archivos)
    assert respuesta.status_code == 201, respuesta.text
    return respuesta.json()


def titulos(api, sesion):
    return sorted(c["titulo"] for c in api.cliente.get("/api/v1/comunicados", headers=sesion).json())


def test_el_comunicado_general_con_foto_llega_a_todo_el_grupo(api, grupo):
    comunicado = publicar(api, grupo["supervisor"], "Parada de planta", imagen=IMAGEN_PNG)

    assert titulos(api, grupo["sesion_carlos"]) == ["Parada de planta"]
    assert titulos(api, grupo["sesion_luis"]) == ["Parada de planta"]
    imagen = api.cliente.get(f"/api/v1/comunicados/{comunicado['id']}/imagen", headers=grupo["sesion_luis"])
    assert imagen.status_code == 200
    assert imagen.content == IMAGEN_PNG  # se guardó en disco y se lee igual


def test_el_comunicado_personal_solo_lo_ve_su_destinatario(api, grupo):
    publicar(api, grupo["supervisor"], "Revisa tu cierre", tecnico_id=grupo["carlos"]["id"])

    assert titulos(api, grupo["sesion_carlos"]) == ["Revisa tu cierre"]
    assert titulos(api, grupo["sesion_luis"]) == []


class ServicioQueAgregaUnidades(ServicioEstandarizacion):
    """Se comporta como el modelo en la prueba con usuarios: agrega °C a valores escritos sin unidad"""

    def estandarizar(self, texto: str) -> str:
        return "Equipo intervenido: Torre TE01\n\nMediciones termográficas:\n- Agua entrada: 35 °C\n- Agua salida: 29 °C"


def test_la_estandarizacion_quita_las_unidades_que_el_tecnico_no_escribio(api, grupo, monkeypatch):
    monkeypatch.setattr(router_estandarizacion, "ServicioEstandarizacionOpenAI", ServicioQueAgregaUnidades)

    respuesta = api.cliente.post(
        "/api/v1/descripciones/estandarizar", headers=grupo["sesion_carlos"],
        json={"texto": "revision de la torre TE01 agua entrada 35 y salida 29"},
    )

    assert respuesta.status_code == 200, respuesta.text
    assert "- Agua entrada: 35\n- Agua salida: 29" in respuesta.json()["texto_estandarizado"]


def test_con_el_almacen_en_postgres_la_imagen_se_guarda_en_la_base(api, grupo, monkeypatch, sesiones):
    # despliegue en Render gratuito: el disco del servidor se borra, las imágenes van a la base
    from sqlalchemy import text

    from src.compartido.configuracion import settings

    monkeypatch.setattr(settings, "comunicados_almacen", "postgres")
    comunicado = publicar(api, grupo["supervisor"], "Parada de planta", imagen=IMAGEN_PNG)

    imagen = api.cliente.get(f"/api/v1/comunicados/{comunicado['id']}/imagen", headers=grupo["sesion_luis"])
    assert imagen.content == IMAGEN_PNG
    with sesiones() as sesion:
        assert sesion.execute(text("SELECT count(*) FROM imagenes_comunicados")).scalar_one() == 1

    api.cliente.delete(f"/api/v1/comunicados/{comunicado['id']}", headers=grupo["supervisor"])
    with sesiones() as sesion:
        assert sesion.execute(text("SELECT count(*) FROM imagenes_comunicados")).scalar_one() == 0
