import 'dart:typed_data';

import '../modelos/comunicado.dart';

abstract interface class RepositorioComunicados {
  /// El técnico recibe los vigentes de su grupo y los dirigidos a él; el supervisor, los que escribió
  Future<List<Comunicado>> listar();

  Future<Comunicado> publicar(ComunicadoNuevo comunicado);

  Future<void> retirar(String comunicadoId);

  Future<Uint8List> imagen(String comunicadoId);
}
