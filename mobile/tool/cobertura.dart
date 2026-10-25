// Resume coverage/lcov.info en porcentajes: total, por capa y archivos con menos cobertura.
// Uso, desde la carpeta mobile:
//   flutter test --coverage
//   dart run tool/cobertura.dart
import 'dart:io';

void main(List<String> argumentos) {
  final archivo = File(argumentos.isNotEmpty ? argumentos.first : 'coverage/lcov.info');
  if (!archivo.existsSync()) {
    stderr.writeln('No existe ${archivo.path}. Ejecuta primero: flutter test --coverage');
    exit(1);
  }

  // por cada archivo: [líneas cubiertas, líneas totales]
  final lineas = <String, List<int>>{};
  String? actual;
  for (final linea in archivo.readAsLinesSync()) {
    if (linea.startsWith('SF:')) {
      actual = linea.substring(3).replaceAll(r'\', '/');
      lineas[actual] = [0, 0];
    } else if (linea.startsWith('DA:') && actual != null) {
      final veces = int.parse(linea.split(',')[1]);
      lineas[actual]![1]++;
      if (veces > 0) lineas[actual]![0]++;
    }
  }

  String porcentaje(int cubiertas, int total) => total == 0 ? '  -  ' : '${(cubiertas * 100 / total).toStringAsFixed(1)}%';

  final capas = <String, List<int>>{};
  for (final MapEntry(key: ruta, value: valor) in lineas.entries) {
    final capa = RegExp(r'lib/(dominio|datos|nucleo|presentacion/[a-z]+)').firstMatch(ruta)?.group(1) ?? 'otros';
    final acumulado = capas.putIfAbsent(capa, () => [0, 0]);
    acumulado[0] += valor[0];
    acumulado[1] += valor[1];
  }

  final cubiertas = lineas.values.fold(0, (suma, v) => suma + v[0]);
  final total = lineas.values.fold(0, (suma, v) => suma + v[1]);
  stdout.writeln('TOTAL ${porcentaje(cubiertas, total)}  ($cubiertas de $total líneas, ${lineas.length} archivos)\n');

  stdout.writeln('Por capa:');
  for (final capa in capas.keys.toList()..sort()) {
    stdout.writeln('  ${capa.padRight(26)} ${porcentaje(capas[capa]![0], capas[capa]![1])}');
  }

  stdout.writeln('\nArchivos con menos del 60 %:');
  final bajos = lineas.entries.where((e) => e.value[1] > 0 && e.value[0] / e.value[1] < 0.6).toList()
    ..sort((a, b) => (a.value[0] / a.value[1]).compareTo(b.value[0] / b.value[1]));
  for (final e in bajos) {
    stdout.writeln('  ${porcentaje(e.value[0], e.value[1]).padLeft(6)}  ${e.key.split('lib/').last}');
  }
}
