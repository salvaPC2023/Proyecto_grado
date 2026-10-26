from datetime import datetime, time

import pytest

from tests.integracion.conftest import PASSWORD_INICIAL

pytestmark = pytest.mark.integracion


def login(api, usuario, password):
    return api.cliente.post("/api/v1/auth/login", json={"nombre_usuario": usuario, "password": password})


# --- restablecer contraseña (prueba con usuarios del 23/10/2026) ---

def test_el_tecnico_restablecido_vuelve_a_la_contrasena_inicial_y_debe_cambiarla(api):
    _, supervisor = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    tecnico, _ = api.crear_tecnico(supervisor, "Carlos", "Mamani")

    respuesta = api.cliente.post(f"/api/v1/tecnicos/{tecnico['id']}/restablecer-password", headers=api.admin())

    assert respuesta.status_code == 200
    assert login(api, tecnico["nombre_usuario"], "Tecn1co!").status_code == 401  # la contraseña anterior ya no sirve
    nueva_sesion = login(api, tecnico["nombre_usuario"], PASSWORD_INICIAL)
    assert nueva_sesion.json()["debe_cambiar_credenciales"] is True
    # hasta que elija una contraseña nueva, la API no le deja usar el sistema
    cabecera = {"Authorization": f"Bearer {nueva_sesion.json()['access_token']}"}
    assert api.cliente.get("/api/v1/ordenes-trabajo/mis-ots", headers=cabecera).status_code == 403


def test_despues_del_restablecimiento_entra_con_su_nueva_contrasena(api):
    datos_supervisor, _ = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    api.cliente.post(f"/api/v1/supervisores/{datos_supervisor['id']}/restablecer-password", headers=api.admin())

    sesion = api.primer_acceso(datos_supervisor["nombre_usuario"], "Otra#Clave9")

    assert api.cliente.get("/api/v1/tecnicos", headers=sesion).status_code == 200


def test_un_supervisor_no_puede_restablecer_contrasenas(api):
    _, supervisor = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    tecnico, _ = api.crear_tecnico(supervisor, "Carlos", "Mamani")

    respuesta = api.cliente.post(f"/api/v1/tecnicos/{tecnico['id']}/restablecer-password", headers=supervisor)

    assert respuesta.status_code == 403


# --- permisos entre grupos y roles ---

def test_un_tecnico_no_ve_la_ot_de_otro_grupo(api):
    _, supervisor_1 = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    _, supervisor_2 = api.crear_supervisor("Patricia", "Vargas", "Grupo 2")
    tecnico_1, _ = api.crear_tecnico(supervisor_1, "Carlos", "Mamani")
    _, sesion_tecnico_2 = api.crear_tecnico(supervisor_2, "Erika", "Villca")
    hoy = datetime.now().date()
    ot = api.cliente.post("/api/v1/ordenes-trabajo", headers=supervisor_1, json={
        "titulo": "Revisión de tablero", "tipo_de_orden": "OE02", "ubicacion_tecnica_id": api.crear_ubicacion()["id"],
        "tecnico_asignado_id": tecnico_1["id"], "prioridad": 2, "estatus_equipo": True,
        "fecha_inic_planif": datetime.combine(hoy, time(8)).isoformat(),
        "fecha_fin_planif": datetime.combine(hoy, time(12)).isoformat(),
        "pasos": [{"descripcion": "Termografía", "clave_control": "PM01", "horas_planificadas": "1"}],
    }).json()

    assert api.cliente.get(f"/api/v1/ordenes-trabajo/{ot['id']}", headers=sesion_tecnico_2).status_code == 403


def test_un_supervisor_no_puede_asignar_una_ot_a_un_tecnico_de_otro_grupo(api):
    _, supervisor_1 = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    _, supervisor_2 = api.crear_supervisor("Patricia", "Vargas", "Grupo 2")
    tecnico_2, _ = api.crear_tecnico(supervisor_2, "Erika", "Villca")
    hoy = datetime.now().date()

    respuesta = api.cliente.post("/api/v1/ordenes-trabajo", headers=supervisor_1, json={
        "titulo": "Revisión de tablero", "tipo_de_orden": "OE02", "ubicacion_tecnica_id": api.crear_ubicacion()["id"],
        "tecnico_asignado_id": tecnico_2["id"], "prioridad": 2, "estatus_equipo": True,
        "fecha_inic_planif": datetime.combine(hoy, time(8)).isoformat(),
        "fecha_fin_planif": datetime.combine(hoy, time(12)).isoformat(),
        "pasos": [{"descripcion": "Termografía", "clave_control": "PM01", "horas_planificadas": "1"}],
    })

    assert respuesta.status_code == 400


def test_un_tecnico_no_puede_crear_ots_ni_administrar(api):
    _, supervisor = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    _, tecnico = api.crear_tecnico(supervisor, "Carlos", "Mamani")

    assert api.cliente.post("/api/v1/ordenes-trabajo", headers=tecnico, json={}).status_code in (403, 422)
    assert api.cliente.get("/api/v1/supervisores", headers=tecnico).status_code == 403
    assert api.cliente.get("/api/v1/grupos", headers=tecnico).status_code == 403


def test_una_cuenta_deshabilitada_no_puede_entrar(api):
    _, supervisor = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    tecnico, _ = api.crear_tecnico(supervisor, "Carlos", "Mamani")

    api.cliente.patch(f"/api/v1/tecnicos/{tecnico['id']}/estado", headers=supervisor, json={"activo": False})

    assert login(api, tecnico["nombre_usuario"], "Tecn1co!").status_code == 401
