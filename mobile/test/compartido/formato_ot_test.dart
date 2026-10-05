import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/presentacion/pantallas/ordenes_trabajo/formato_ot.dart';

void main() {
  group('formatoHoras', () {
    test('usa singular para una hora', () {
      expect(formatoHoras(1), '1 Hora');
    });

    test('quita los decimales cuando el número es entero', () {
      expect(formatoHoras(3), '3 Horas');
    });

    test('muestra un decimal cuando no es entero', () {
      expect(formatoHoras(2.5), '2.5 Horas');
    });
  });

  test('formatoFecha y formatoHora rellenan con ceros', () {
    final fecha = DateTime(2026, 3, 7, 9, 5);
    expect(formatoFecha(fecha), '07 Mar 2026');
    expect(formatoHora(fecha), '09:05');
  });

  group('estiloEstatus', () {
    test('traduce los estatus conocidos', () {
      expect(estiloEstatus('en_progreso').texto, 'En proceso');
      expect(estiloEstatus('cerrada').texto, 'Finalizada');
    });

    test('muestra el valor original si no lo reconoce', () {
      expect(estiloEstatus('otro').texto, 'otro');
    });
  });

  test('estiloPrioridad trata cualquier valor mayor a 3 como Baja', () {
    expect(estiloPrioridad(1).texto, 'Urgente');
    expect(estiloPrioridad(9).texto, 'Baja');
  });
}
