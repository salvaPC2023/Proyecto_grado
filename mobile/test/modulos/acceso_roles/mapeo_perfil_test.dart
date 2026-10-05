import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/mapeo_json.dart';

void main() {
  test('perfilDesdeJson arma el nombre completo sin apellido materno', () {
    final perfil = perfilDesdeJson({
      'id': 'u1',
      'nombre': 'Ana',
      'apellido_paterno': 'Rojas',
      'apellido_materno': null,
      'nombre_usuario': 'ana',
      'rol': 'supervisor',
    });

    expect(perfil.nombreCompleto, 'Ana Rojas');
    expect(perfil.esSupervisor, isTrue);
  });
}
