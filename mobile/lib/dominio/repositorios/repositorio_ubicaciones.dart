import '../modelos/orden_trabajo.dart';

abstract interface class RepositorioUbicaciones {
  Future<List<UbicacionTecnica>> listar();

  /// Sin id crea una ubicación nueva; con id la edita
  Future<void> guardar({String? id, required String sector, String? subsector, String? sistema, String? subsistema});

  Future<void> borrar(String id);
}
