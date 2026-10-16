import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/nucleo/sesion.dart';

void main() {
  test('cada rol tiene su imagen por defecto', () {
    expect(const SesionUsuario(token: 't', rol: 'administrador').imagenAvatar,
        'assets/images/icono_administrador.png');
    expect(const SesionUsuario(token: 't', rol: 'supervisor').imagenAvatar,
        'assets/images/icono_supervisor.png');
    expect(const SesionUsuario(token: 't', rol: 'tecnico').imagenAvatar,
        'assets/images/icono_tecnico.png');
  });
}