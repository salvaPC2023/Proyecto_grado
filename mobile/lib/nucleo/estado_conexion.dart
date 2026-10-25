import 'package:flutter_riverpod/flutter_riverpod.dart';

/// null: los datos en pantalla vienen del servidor. Con fecha: no hay conexión y se muestran
/// los datos guardados a esa hora (las OT del técnico y su detalle)
class DatosSinConexionNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void mostrandoDatosDe(DateTime? guardadoEn) => state = guardadoEn;
}

final datosSinConexionProvider = NotifierProvider<DatosSinConexionNotifier, DateTime?>(DatosSinConexionNotifier.new);
