import 'dart:typed_data';

abstract interface class RepositorioExcel {
  /// Devuelve el archivo .xlsx con las OT del grupo del supervisor
  Future<Uint8List> exportarOts({DateTime? desde, DateTime? hasta, String? ubicacionTecnicaId});
}
