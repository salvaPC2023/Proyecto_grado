import 'dart:typed_data';

import '../modelos/resultado_importacion.dart';

abstract interface class RepositorioExcel {
  /// Devuelve el archivo .xlsx con las OT del grupo del supervisor
  Future<Uint8List> exportarOts({DateTime? desde, DateTime? hasta, String? ubicacionTecnicaId});

  /// Administrador, carga inicial: ubicaciones técnicas, supervisores y técnicos de todos los grupos
  Future<ResultadoImportacion> importarCargaInicial(Uint8List archivo, String nombreArchivo);

  /// Supervisor: ubicaciones técnicas y técnicos de su grupo
  Future<ResultadoImportacion> importarParaMiGrupo(Uint8List archivo, String nombreArchivo);
}
