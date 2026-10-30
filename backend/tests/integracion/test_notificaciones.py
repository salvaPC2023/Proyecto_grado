import pytest
from sqlalchemy import text

pytestmark = pytest.mark.integracion


def dueno_del_token(sesiones, token):
    with sesiones() as sesion:
        return sesion.execute(
            text("SELECT u.nombre_usuario FROM dispositivos d JOIN usuarios u ON u.id = d.usuario_id WHERE d.token = :t"),
            {"t": token},
        ).scalar_one_or_none()


def test_el_celular_queda_registrado_y_pasa_a_quien_inicia_sesion_despues(api, sesiones):
    # tarjeta 23: un mismo celular puede pasar de un técnico a otro entre turnos
    datos_supervisor, supervisor = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    tecnico, sesion_tecnico = api.crear_tecnico(supervisor, "Carlos", "Mamani")

    assert api.cliente.put("/api/v1/notificaciones/dispositivo", headers=sesion_tecnico, json={"token": "celular-1"}).status_code == 204
    assert dueno_del_token(sesiones, "celular-1") == tecnico["nombre_usuario"]

    api.cliente.put("/api/v1/notificaciones/dispositivo", headers=supervisor, json={"token": "celular-1"})
    assert dueno_del_token(sesiones, "celular-1") == datos_supervisor["nombre_usuario"]


def test_sin_sesion_no_se_registra_un_celular(api):
    assert api.cliente.put("/api/v1/notificaciones/dispositivo", json={"token": "celular-1"}).status_code in (401, 403)


class ServicioQueAnota:
    """Reemplaza a Firebase: anota lo que se habría enviado"""
    enviados: list = []

    def enviar(self, tokens, titulo, cuerpo):
        ServicioQueAnota.enviados.append((tokens, titulo, cuerpo))
        return []


def test_el_comunicado_personal_llega_como_notificacion_y_el_general_no(api, monkeypatch):
    from datetime import datetime, timedelta

    from src.modulos.comunicados.infraestructura import router as router_comunicados

    monkeypatch.setattr(router_comunicados, "ServicioNotificacionesFirebase", ServicioQueAnota)
    ServicioQueAnota.enviados = []
    _, supervisor = api.crear_supervisor("Fernando", "Rojas", "Grupo 1")
    tecnico, sesion_tecnico = api.crear_tecnico(supervisor, "Carlos", "Mamani")
    api.cliente.put("/api/v1/notificaciones/dispositivo", headers=sesion_tecnico, json={"token": "celular-carlos"})
    expira = (datetime.now() + timedelta(days=2)).isoformat()

    general = {"titulo": "Parada de planta", "categoria": "general", "texto": "Mañana", "fecha_expiracion": expira}
    assert api.cliente.post("/api/v1/comunicados", headers=supervisor, data=general).status_code == 201
    assert ServicioQueAnota.enviados == []

    personal = {**general, "titulo": "Revisa tu cierre", "tecnico_id": tecnico["id"]}
    assert api.cliente.post("/api/v1/comunicados", headers=supervisor, data=personal).status_code == 201
    assert ServicioQueAnota.enviados == [(["celular-carlos"], "Comunicado personal", "Fernando Rojas: Revisa tu cierre")]
