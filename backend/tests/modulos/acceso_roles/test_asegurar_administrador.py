from src.compartido.seguridad import verificar_password
from src.modulos.acceso_roles.aplicacion.asegurar_administrador import asegurar_administrador
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


def test_sin_administradores_crea_el_inicial_y_debe_cambiar_la_password():
    usuarios = RepositorioUsuariosFalso()

    creado = asegurar_administrador("admin", "Inicial#2026", usuarios)

    usuario = usuarios.obtener_por_nombre_usuario("admin")
    assert creado is True
    assert usuario.rol == "admin"
    assert verificar_password("Inicial#2026", usuario.password_hash)
    assert usuario.debe_cambiar_password is True


def test_si_ya_hay_un_administrador_no_crea_otro():
    jefe = crear_usuario(nombre_usuario="jefe")
    jefe.rol = "admin"
    usuarios = RepositorioUsuariosFalso([jefe])

    creado = asegurar_administrador("admin", "Inicial#2026", usuarios)

    assert creado is False
    assert usuarios.obtener_por_nombre_usuario("admin") is None


def test_no_pisa_a_un_usuario_que_ya_usa_ese_nombre():
    usuarios = RepositorioUsuariosFalso([crear_usuario(nombre_usuario="admin")])

    creado = asegurar_administrador("admin", "Inicial#2026", usuarios)

    assert creado is False
    assert usuarios.obtener_por_nombre_usuario("admin").rol == "comun"


def test_los_usuarios_creados_normalmente_son_de_rol_comun():
    assert crear_usuario().rol == "comun"
