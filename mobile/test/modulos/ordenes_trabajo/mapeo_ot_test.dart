import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/mapeo_json.dart';

void main() {
  test('ordenTrabajoDesdeJson convierte fechas, pasos y horas en texto', () {
    final orden = ordenTrabajoDesdeJson({
      'id': 'ot1',
      'titulo': 'Cambiar filtro',
      'tipo_de_orden': 'correctivo',
      'tecnico_asignado_id': 't1',
      'descripcion': 'Filtro de aire',
      'prioridad': 2,
      'estatus': 'asignada',
      'estatus_equipo': true,
      'fecha_inic_planif': '2026-10-01T08:00:00',
      'fecha_fin_planif': '2026-10-01T12:00:00',
      'fecha_cierre': null,
      'ubicacion': null,
      'pasos': [
        {
          'id': 'p1',
          'numero_paso': 1,
          'descripcion': 'Desmontar',
          'clave_control': 'PM01',
          'horas_planificadas': '1.5',
          'cierre': null,
        },
      ],
    });

    expect(orden.fechaInicPlanif, DateTime(2026, 10, 1, 8));
    expect(orden.fechaCierre, isNull);
    expect(orden.pasos.single.horasPlanificadas, 1.5);
  });
}
