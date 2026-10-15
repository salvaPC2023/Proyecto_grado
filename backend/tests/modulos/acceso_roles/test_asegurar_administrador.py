from src.compartido.seguridad import verificar_password
from src.modulos.acceso_roles.aplicacion.asegurar_administrador import asegurar_administrador
from src.modulos.acceso_roles.dominio.puertos import RepositorioAdministradores
from tests.modulos.acceso_roles.repositorios_falsos import RepositorioUsuariosFalso, crear_usuario


class RepositorioAdministradoresFalso(RepositorioAdministradores):
    def __init__(self, usuario_ids=None):
        self.usuario_ids = list(usuario_ids or [])

    def existe_alguno(self):
        return bool(self.usuario_ids)

    def crear(self, usuario_id):
        self.usuario_ids.append(usuario_id)


def test_sin_administradores_crea_el_inicial_y_debe_cambiar_la_password():
    usuarios = RepositorioUsuariosFalso()
    administradores = RepositorioAdministradoresFalso()

    creado = asegurar_administrador("admin", "Inicial#2026", usuarios, administradores)

    usuario = usuarios.obtener_por_nombre_usuario("admin")
    assert creado is True
    assert administradores.usuario_ids == [usuario.id]
    assert verificar_password("Inicial#2026", usuario.password_hash)
    assert usuario.debe_cambiar_password is True


def test_si_ya_hay_un_administrador_no_crea_otro():
    administradores = RepositorioAdministradoresFalso([crear_usuario(nombre_usuario="jefe").id])

    creado = asegurar_administrador("admin", "Inicial#2026", RepositorioUsuariosFalso(), administradores)

    assert creado is False
    assert len(administradores.usuario_ids) == 1


def test_no_pisa_a_un_usuario_que_ya_usa_ese_nombre():
    usuarios = RepositorioUsuariosFalso([crear_usuario(nombre_usuario="admin")])
    administradores = RepositorioAdministradoresFalso()

    creado = asegurar_administrador("admin", "Inicial#2026", usuarios, administradores)

    assert creado is False
    assert administradores.usuario_ids == []
