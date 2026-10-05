import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/modelos/orden_trabajo.dart';

import 'repositorios_falsos.dart';

void main() {
  test('las horas planificadas solo suman los pasos PM01', () {
    final ot = crearOt();

    expect(ot.horasPlanificadas, 2);
    expect(ot.pm01Total, 1);
    expect(ot.pm01Cerrados, 0);
  });

  test('un paso con cierre cuenta como cerrado', () {
    final paso = PasoOt(
      id: 'p1',
      numeroPaso: 1,
      descripcion: 'Cambiar filtro',
      claveControl: 'PM01',
      cierre: cierreEjecutado,
    );

    expect(paso.cerrado, isTrue);
    expect(crearOt(pasos: [paso]).pm01Cerrados, 1);
  });
}
