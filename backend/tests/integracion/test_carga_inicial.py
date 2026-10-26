import pytest

from tests.integracion.conftest import PASSWORD_INICIAL, plantilla_excel

pytestmark = pytest.mark.integracion

PERSONAL = [
    ("Carlos Mamani Quispe", "Mecanico", "Fernando Rojas Aguilar"),
    ("Luis Torrez Vargas", "Electronico", "Fernando Rojas Aguilar"),
    ("Erika Villca Nina", "Electrico", "Patricia Vargas Mendoza"),
]
GRUPOS = [
    ("Grupo 1", "Turno 1", "Fernando Rojas Aguilar"),
    ("Grupo 2", "Turno 3", "Patricia Vargas Mendoza"),
]
UBICACIONES = [
    ("Embotellado", "Area 1", "Llenadora", "Sistema de Dosificacion"),
    ("Embotellado", "Area 1", "Llenadora", "Sistema de Tapado"),
]


def importar(api, contenido: bytes):
    return api.cliente.post(
        "/api/v1/importacion/carga-inicial", headers=api.admin(),
        files={"archivo": ("plantilla.xlsx", contenido, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")},
    )


def test_la_carga_inicial_crea_supervisores_tecnicos_y_ubicaciones(api):
    respuesta = importar(api, plantilla_excel(PERSONAL, GRUPOS, UBICACIONES))

    assert respuesta.status_code == 200, respuesta.text
    resultado = respuesta.json()
    roles = sorted(u["rol"] for u in resultado["usuarios_creados"])
    assert roles == ["supervisor", "supervisor", "tecnico", "tecnico", "tecnico"]
    assert resultado["ubicaciones_creadas"] == 2
    assert resultado["errores"] == []


def test_las_personas_cargadas_pueden_entrar_con_la_contrasena_inicial(api):
    creados = importar(api, plantilla_excel(PERSONAL, GRUPOS, UBICACIONES)).json()["usuarios_creados"]
    supervisor = next(u for u in creados if u["rol"] == "supervisor")

    respuesta = api.cliente.post(
        "/api/v1/auth/login", json={"nombre_usuario": supervisor["nombre_usuario"], "password": PASSWORD_INICIAL},
    )

    assert respuesta.status_code == 200
    assert respuesta.json()["debe_cambiar_credenciales"] is True


def test_cada_supervisor_ve_solo_a_los_tecnicos_de_su_grupo(api):
    creados = importar(api, plantilla_excel(PERSONAL, GRUPOS, UBICACIONES)).json()["usuarios_creados"]
    fernando = next(u for u in creados if u["nombre_completo"].startswith("Fernando"))
    sesion = api.primer_acceso(fernando["nombre_usuario"], "Superv1sor!")

    tecnicos = api.cliente.get("/api/v1/tecnicos", headers=sesion).json()

    assert sorted(t["nombre"] for t in tecnicos) == ["Carlos", "Luis"]


def test_importar_dos_veces_el_mismo_archivo_no_duplica_nada(api):
    contenido = plantilla_excel(PERSONAL, GRUPOS, UBICACIONES)
    importar(api, contenido)

    segunda = importar(api, contenido).json()

    assert segunda["usuarios_creados"] == []
    assert segunda["ubicaciones_creadas"] == 0
    assert len(segunda["omitidos"]) > 0
