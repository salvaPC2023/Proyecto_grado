import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/mapeo_json.dart';
import 'package:maintenance_app/dominio/modelos/orden_trabajo.dart';

void main() {
  const ubicacion = UbicacionTecnica(
    id: 'ub1',
    sector: 'Planta Norte',
    subsector: 'Subestación A',
    sistema: 'Transformadores',
  );

  test('la ruta une todos los niveles', () {
    expect(ubicacion.ruta, 'Planta Norte / Subestación A / Transformadores');
  });

  test('el nombre corto es el último nivel', () {
    expect(ubicacion.nombreCorto, 'Transformadores');
  });

  test('el resumen muestra los dos últimos niveles', () {
    expect(ubicacion.resumen, 'Subestación A · Transformadores');
  });

  test('ubicacionDesdeJson lee los niveles vacíos como null', () {
    final leida = ubicacionDesdeJson({
      'id': 'ub2',
      'sector': 'Almacén',
      'subsector': null,
      'sistema': null,
      'subsistema': null,
    });

    expect(leida.ruta, 'Almacén');
    expect(leida.subsector, isNull);
  });
}
