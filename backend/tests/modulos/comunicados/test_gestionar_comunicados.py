from datetime import datetime, time, timedelta
from uuid import uuid4

import pytest

from src.modulos.acceso_roles.dominio.modelos import Supervisor, Tecnico
from src.modulos.comunicados.aplicacion.gestionar_comunicados import (
    ComunicadoNoEncontrado, ComunicadoVacio, ExpiracionInvalida, ImagenInvalida, NoEsElAutor, SupervisorSinGrupo,
    TecnicoAjeno, TituloVacio, listar_comunicados, obtener_imagen, publicar_comunicado, retirar_comunicado,
)
from src.modulos.comunicados.dominio.puertos import AlmacenImagenes, RepositorioComunicados
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioSupervisoresFalso
from tests.modulos.ordenes_trabajo.repositorios_falsos import RepositorioTecnicosFalso

AHORA = datetime(2026, 10, 21, 9, 0)
MANANA = AHORA + timedelta(days=1)
PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 100
JPG = b"\xff\xd8\xff" + b"0" * 100

GRUPO_A, GRUPO_B = uuid4(), uuid4()
SUPERVISOR_A = Supervisor(id=uuid4(), usuario_id=uuid4(), horario_entrada=time(7), horario_salida=time(15))
SUPERVISOR_B = Supervisor(id=uuid4(), usuario_id=uuid4(), horario_entrada=time(15), horario_salida=time(23))
CARLOS = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=GRUPO_A, profesion="mecanico")
LUIS = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=GRUPO_A, profesion="electrico")
ERIKA = Tecnico(id=uuid4(), usuario_id=uuid4(), grupo_id=GRUPO_B, profesion="electrico")


class RepositorioComunicadosFalso(RepositorioComunicados):
    def __init__(self):
        self.comunicados = {}

    def crear(self, comunicado):
        self.comunicados[comunicado.id] = comunicado
        return comunicado

    def obtener_por_id(self, id):
        return self.comunicados.get(id)

    def listar_vigentes_para_tecnico(self, grupo_id, tecnico_id, ahora):
        return [c for c in self.comunicados.values()
                if c.grupo_id == grupo_id and c.vigente(ahora) and c.tecnico_id in (None, tecnico_id)]

    def listar_vigentes_de_supervisor(self, supervisor_id, ahora):
        return [c for c in self.comunicados.values() if c.supervisor_id == supervisor_id and c.vigente(ahora)]

    def eliminar(self, id):
        self.comunicados.pop(id, None)


class AlmacenFalso(AlmacenImagenes):
    def __init__(self):
        self.archivos = {}

    def guardar(self, contenido, extension):
        nombre = f"{uuid4().hex}.{extension}"
        self.archivos[nombre] = contenido
        return nombre

    def leer(self, nombre):
        return self.archivos.get(nombre)

    def eliminar(self, nombre):
        self.archivos.pop(nombre, None)


@pytest.fixture
def sistema():
    class Sistema:
        comunicados = RepositorioComunicadosFalso()
        supervisores = RepositorioSupervisoresFalso([SUPERVISOR_A, SUPERVISOR_B])
        tecnicos = RepositorioTecnicosFalso(
            supervisor_de_tecnico={CARLOS.id: SUPERVISOR_A.usuario_id, LUIS.id: SUPERVISOR_A.usuario_id, ERIKA.id: SUPERVISOR_B.usuario_id},
            tecnicos=[CARLOS, LUIS, ERIKA],
            grupo_de_supervisor={SUPERVISOR_A.usuario_id: GRUPO_A, SUPERVISOR_B.usuario_id: GRUPO_B},
        )
        almacen = AlmacenFalso()

        def publicar(self, supervisor=SUPERVISOR_A, titulo="Uso de EPP", texto="Casco obligatorio", expira=MANANA, **otros):
            return publicar_comunicado(
                supervisor.usuario_id, titulo, "seguridad", expira,
                self.comunicados, self.supervisores, self.tecnicos, self.almacen, AHORA, texto=texto, **otros,
            )

        def ve(self, usuario_id, rol, ahora=AHORA):
            return listar_comunicados(usuario_id, rol, self.comunicados, self.supervisores, self.tecnicos, ahora)

    return Sistema()


# --- publicar ---

def test_publica_un_comunicado_general_para_el_grupo_del_supervisor(sistema):
    comunicado = sistema.publicar()

    assert comunicado.grupo_id == GRUPO_A
    assert comunicado.supervisor_id == SUPERVISOR_A.id
    assert not comunicado.es_personal
    assert comunicado.fecha_envio == AHORA


def test_publica_un_comunicado_personal_para_un_tecnico_del_grupo(sistema):
    comunicado = sistema.publicar(tecnico_id=CARLOS.id)

    assert comunicado.es_personal


def test_no_puede_enviar_un_comunicado_personal_a_un_tecnico_de_otro_grupo(sistema):
    with pytest.raises(TecnicoAjeno):
        sistema.publicar(tecnico_id=ERIKA.id)


def test_basta_una_imagen_sin_texto(sistema):
    comunicado = sistema.publicar(texto=None, imagen=PNG)

    assert comunicado.imagen.endswith(".png")
    assert sistema.almacen.leer(comunicado.imagen) == PNG


def test_sin_texto_ni_imagen_lanza_error(sistema):
    with pytest.raises(ComunicadoVacio):
        sistema.publicar(texto="   ")


def test_sin_titulo_lanza_error(sistema):
    with pytest.raises(TituloVacio):
        sistema.publicar(titulo="  ")


def test_la_expiracion_debe_ser_posterior_al_envio(sistema):
    with pytest.raises(ExpiracionInvalida):
        sistema.publicar(expira=AHORA)


def test_un_archivo_que_no_es_jpg_ni_png_se_rechaza(sistema):
    # aunque se llame "foto.png", se revisa el contenido
    with pytest.raises(ImagenInvalida, match="JPG o PNG"):
        sistema.publicar(imagen=b"GIF89a" + b"0" * 100)


def test_una_imagen_de_mas_de_2_mb_se_rechaza(sistema):
    with pytest.raises(ImagenInvalida, match="2 MB"):
        sistema.publicar(imagen=JPG + b"0" * (2 * 1024 * 1024))
    assert sistema.almacen.archivos == {}  # no se guardó nada


def test_supervisor_sin_grupo_no_puede_publicar(sistema):
    sin_grupo = Supervisor(id=uuid4(), usuario_id=uuid4(), horario_entrada=time(7), horario_salida=time(15))

    with pytest.raises(SupervisorSinGrupo):
        sistema.publicar(supervisor=sin_grupo)


# --- quién ve qué ---

def test_el_tecnico_ve_los_generales_de_su_grupo_y_los_personales_dirigidos_a_el(sistema):
    general = sistema.publicar(titulo="General")
    para_carlos = sistema.publicar(titulo="Para Carlos", tecnico_id=CARLOS.id)
    sistema.publicar(titulo="Para Luis", tecnico_id=LUIS.id)
    sistema.publicar(supervisor=SUPERVISOR_B, titulo="Del otro grupo")

    vistos = sistema.ve(CARLOS.usuario_id, "tecnico")

    assert {c.id for c in vistos} == {general.id, para_carlos.id}


def test_los_vencidos_dejan_de_mostrarse(sistema):
    sistema.publicar()

    assert sistema.ve(CARLOS.usuario_id, "tecnico", ahora=MANANA + timedelta(minutes=1)) == []


def test_el_supervisor_ve_los_que_escribio(sistema):
    general = sistema.publicar(titulo="General")
    personal = sistema.publicar(titulo="Para Carlos", tecnico_id=CARLOS.id)
    sistema.publicar(supervisor=SUPERVISOR_B, titulo="De otro supervisor")

    vistos = sistema.ve(SUPERVISOR_A.usuario_id, "supervisor")

    assert {c.id for c in vistos} == {general.id, personal.id}


def test_el_administrador_no_ve_comunicados(sistema):
    sistema.publicar()

    assert sistema.ve(uuid4(), "administrador") == []


# --- retirar ---

def test_quien_lo_escribio_puede_retirarlo_y_se_borra_su_imagen(sistema):
    comunicado = sistema.publicar(imagen=PNG)

    retirar_comunicado(comunicado.id, SUPERVISOR_A.usuario_id, sistema.comunicados, sistema.supervisores, sistema.almacen)

    assert sistema.ve(CARLOS.usuario_id, "tecnico") == []
    assert sistema.almacen.archivos == {}


def test_otro_supervisor_no_puede_retirarlo(sistema):
    comunicado = sistema.publicar()

    with pytest.raises(NoEsElAutor):
        retirar_comunicado(comunicado.id, SUPERVISOR_B.usuario_id, sistema.comunicados, sistema.supervisores, sistema.almacen)


def test_retirar_uno_inexistente_lanza_error(sistema):
    with pytest.raises(ComunicadoNoEncontrado):
        retirar_comunicado(uuid4(), SUPERVISOR_A.usuario_id, sistema.comunicados, sistema.supervisores, sistema.almacen)


# --- imagen ---

def _imagen(sistema, comunicado, usuario_id, rol):
    return obtener_imagen(comunicado.id, usuario_id, rol, sistema.comunicados, sistema.supervisores, sistema.tecnicos, sistema.almacen)


def test_el_destinatario_ve_la_imagen(sistema):
    comunicado = sistema.publicar(imagen=JPG, tecnico_id=CARLOS.id)

    assert _imagen(sistema, comunicado, CARLOS.usuario_id, "tecnico") == (JPG, "jpg")


def test_otro_tecnico_no_ve_la_imagen_de_un_comunicado_personal_ajeno(sistema):
    comunicado = sistema.publicar(imagen=JPG, tecnico_id=CARLOS.id)

    with pytest.raises(ComunicadoNoEncontrado):
        _imagen(sistema, comunicado, LUIS.usuario_id, "tecnico")


def test_un_tecnico_de_otro_grupo_no_ve_la_imagen(sistema):
    comunicado = sistema.publicar(imagen=JPG)

    with pytest.raises(ComunicadoNoEncontrado):
        _imagen(sistema, comunicado, ERIKA.usuario_id, "tecnico")
