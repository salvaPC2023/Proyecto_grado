from datetime import date, datetime, time
from decimal import Decimal
from uuid import uuid4

from src.modulos.acceso_roles.dominio.modelos import Grupo, Supervisor, Tecnico
from src.modulos.notificaciones.aplicacion.avisos_fin_de_turno import avisos_del_turno, enviar_avisos_de_fin_de_turno, turnos_por_avisar
from src.modulos.notificaciones.dominio.puertos import RepositorioDispositivos, ServicioNotificaciones
from src.modulos.ordenes_trabajo.dominio.modelos import CierrePaso, OrdenDeTrabajo, PasoOT
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioSupervisoresFalso, RepositorioTecnicosFalso, RepositorioUsuariosFalso, crear_usuario

# Tarjeta 23: una hora antes del fin del turno se avisa a quien le queden pasos PM01 sin cerrar

DIA = date(2026, 10, 27)


def grupo(salida: time, supervisor_id=None) -> Grupo:
    return Grupo(id=uuid4(), nombre_de_grupo="Grupo 1", supervisor_id=supervisor_id, horario_entrada=time(7), horario_salida=salida)


# --- cuándo se avisa ---

def test_el_turno_que_sale_a_las_15_se_avisa_a_las_14():
    tarde = grupo(time(15))

    assert turnos_por_avisar([tarde], datetime(2026, 10, 27, 13, 55), datetime(2026, 10, 27, 14, 0)) == [(tarde, DIA)]
    assert turnos_por_avisar([tarde], datetime(2026, 10, 27, 14, 0), datetime(2026, 10, 27, 14, 5)) == []  # ya se avisó


def test_el_turno_de_noche_se_avisa_a_las_6_del_dia_en_que_termina():
    noche = grupo(time(7))

    assert turnos_por_avisar([noche], datetime(2026, 10, 27, 5, 58), datetime(2026, 10, 27, 6, 3)) == [(noche, DIA)]


def test_un_turno_que_sale_pasada_la_medianoche_se_avisa_el_dia_anterior():
    madrugada = grupo(time(0, 30))

    assert turnos_por_avisar([madrugada], datetime(2026, 10, 26, 23, 28), datetime(2026, 10, 26, 23, 33)) == [(madrugada, DIA)]


# --- a quién se avisa ---

class RepositorioOtsFalso:
    def __init__(self, ots_por_tecnico):
        self.ots_por_tecnico = ots_por_tecnico

    def listar_por_tecnico(self, tecnico_id, fecha=None):
        return self.ots_por_tecnico.get(tecnico_id, [])


def ot(tecnico_id, cerrados=0, abiertos=1, estatus="en_progreso") -> OrdenDeTrabajo:
    ot_id = uuid4()
    pasos = [PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=None, descripcion="Seguridad", clave_control="PMNN")]
    for i in range(cerrados + abiertos):
        paso = PasoOT(id=uuid4(), ot_id=ot_id, numero_paso=i + 1, descripcion="Paso", clave_control="PM01", horas_planificadas=Decimal("1"))
        if i < cerrados:
            paso.cierre = CierrePaso(uuid4(), paso.id, datetime(2026, 10, 27, 10), Decimal("1"), True, False, "ejecutado", "Hecho")
        pasos.append(paso)
    return OrdenDeTrabajo(
        id=ot_id, titulo="OT", tipo_de_orden="OE01", ubicacion_tecnica_id=uuid4(), tecnico_asignado_id=tecnico_id,
        creado_por_id=uuid4(), prioridad=2, estatus_equipo=True, estatus=estatus,
        fecha_inic_planif=datetime(2026, 10, 27, 8), fecha_fin_planif=datetime(2026, 10, 27, 14), pasos=pasos,
    )


def escenario(ots_de=lambda carlos, luis: {}, activo_luis=True):
    """Un grupo con su supervisor y dos técnicos: Carlos y Luis"""
    usuario_supervisor = crear_usuario("frojas")
    supervisor = Supervisor(id=uuid4(), usuario_id=usuario_supervisor.id, horario_entrada=time(7), horario_salida=time(15))
    g = grupo(time(15), supervisor.id)
    usuario_carlos, usuario_luis = crear_usuario("cmamani"), crear_usuario("ltorrez", activo=activo_luis)
    usuario_carlos.nombre, usuario_carlos.apellido_paterno = "Carlos", "Mamani"
    usuario_luis.nombre, usuario_luis.apellido_paterno = "Luis", "Torrez"
    carlos = Tecnico(id=uuid4(), usuario_id=usuario_carlos.id, grupo_id=g.id, profesion="mecanico")
    luis = Tecnico(id=uuid4(), usuario_id=usuario_luis.id, grupo_id=g.id, profesion="electrico")
    repositorios = dict(
        repositorio_tecnicos=RepositorioTecnicosFalso([carlos, luis]),
        repositorio_usuarios=RepositorioUsuariosFalso([usuario_supervisor, usuario_carlos, usuario_luis]),
        repositorio_supervisores=RepositorioSupervisoresFalso([supervisor]),
        repositorio_ots=RepositorioOtsFalso(ots_de(carlos.id, luis.id)),
    )
    return g, repositorios, {"supervisor": usuario_supervisor.id, "carlos": usuario_carlos.id, "luis": usuario_luis.id}


def test_avisa_a_cada_tecnico_sus_pasos_pendientes_y_al_supervisor_un_resumen():
    g, repositorios, ids = escenario(lambda carlos, luis: {carlos: [ot(carlos, cerrados=1, abiertos=2)], luis: [ot(luis)]})

    avisos = {a.usuario_id: a.cuerpo for a in avisos_del_turno(g, DIA, **repositorios)}

    assert avisos[ids["carlos"]].startswith("Tienes 2 pasos sin cerrar")
    assert avisos[ids["luis"]].startswith("Tienes 1 paso sin cerrar")
    assert avisos[ids["supervisor"]] == "2 técnicos de Grupo 1 con pasos sin cerrar: Carlos Mamani (2 pasos), Luis Torrez (1 paso)"


def test_sin_pasos_pendientes_no_se_avisa_a_nadie():
    g, repositorios, _ = escenario(lambda carlos, luis: {carlos: [ot(carlos, cerrados=2, abiertos=0)]})

    assert avisos_del_turno(g, DIA, **repositorios) == []


def test_no_cuenta_las_ot_cerradas_ni_a_los_tecnicos_deshabilitados():
    g, repositorios, ids = escenario(
        lambda carlos, luis: {carlos: [ot(carlos, estatus="cerrada")], luis: [ot(luis)]}, activo_luis=False,
    )

    assert avisos_del_turno(g, DIA, **repositorios) == []


# --- envío ---

class DispositivosFalsos(RepositorioDispositivos):
    def __init__(self, tokens):
        self.tokens = tokens  # usuario_id -> tokens
        self.eliminados = []

    def registrar(self, usuario_id, token): ...
    def tokens_de(self, usuario_id): return self.tokens.get(usuario_id, [])
    def eliminar(self, tokens): self.eliminados.extend(tokens)


class ServicioFalso(ServicioNotificaciones):
    def __init__(self, invalidos=()):
        self.enviados = []
        self.invalidos = list(invalidos)

    def enviar(self, tokens, titulo, cuerpo):
        self.enviados.append((tuple(tokens), cuerpo))
        return [t for t in tokens if t in self.invalidos]


class GruposFalsos:
    def __init__(self, grupos):
        self.grupos = grupos

    def listar(self):
        return self.grupos


def test_envia_a_los_celulares_de_cada_usuario_y_borra_los_tokens_que_ya_no_sirven():
    g, repositorios, ids = escenario(lambda carlos, luis: {carlos: [ot(carlos)]})
    dispositivos = DispositivosFalsos({ids["carlos"]: ["celular-carlos", "celular-viejo"], ids["supervisor"]: ["celular-supervisor"]})
    servicio = ServicioFalso(invalidos=["celular-viejo"])

    enviadas = enviar_avisos_de_fin_de_turno(
        datetime(2026, 10, 27, 13, 55), datetime(2026, 10, 27, 14, 0), GruposFalsos([g]), **repositorios,
        repositorio_dispositivos=dispositivos, servicio=servicio,
    )

    assert len(enviadas) == 2
    assert ("celular-carlos", "celular-viejo") in [tokens for tokens, _ in servicio.enviados]
    assert dispositivos.eliminados == ["celular-viejo"]


def test_quien_no_tiene_celular_registrado_no_genera_envio():
    g, repositorios, _ = escenario(lambda carlos, luis: {carlos: [ot(carlos)]})
    servicio = ServicioFalso()

    enviar_avisos_de_fin_de_turno(
        datetime(2026, 10, 27, 13, 55), datetime(2026, 10, 27, 14, 0), GruposFalsos([g]), **repositorios,
        repositorio_dispositivos=DispositivosFalsos({}), servicio=servicio,
    )

    assert servicio.enviados == []
