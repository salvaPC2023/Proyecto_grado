from src.modulos.acceso_roles.dominio.nombre_usuario import ALFABETO, generar_nombre_usuario


def _nunca_ocupado(candidato):
    return False


def test_tiene_8_caracteres_y_empieza_con_las_iniciales_de_los_apellidos():
    nombre_usuario = generar_nombre_usuario("Carlos", "Mamani", "Quispe", _nunca_ocupado)

    assert len(nombre_usuario) == 8
    assert nombre_usuario[:2] == "mq"
    assert all(c in ALFABETO for c in nombre_usuario[2:])


def test_sin_apellido_materno_usa_la_inicial_del_nombre():
    assert generar_nombre_usuario("Wilson", "Choquehuanca", None, _nunca_ocupado)[:2] == "cw"


def test_quita_tildes_y_enie():
    assert generar_nombre_usuario("Ana", "Ñuflo", "Álvarez", _nunca_ocupado)[:2] == "na"


def test_no_devuelve_un_usuario_ocupado():
    ocupados = set()

    def esta_ocupado(candidato):
        # los 3 primeros intentos salen ocupados
        if len(ocupados) < 3:
            ocupados.add(candidato)
            return True
        return candidato in ocupados

    nombre_usuario = generar_nombre_usuario("Carlos", "Mamani", "Quispe", esta_ocupado)

    assert nombre_usuario not in ocupados
