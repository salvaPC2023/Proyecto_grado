import '../modelos/cierre_pendiente.dart';

/// Cola de cierres guardada en el celular: sobrevive a cerrar la app
abstract interface class RepositorioColaCierres {
  Future<List<CierrePendiente>> leer();

  Future<void> guardar(List<CierrePendiente> cierres);
}

/// Sesión guardada de forma cifrada, para enviar la cola aunque se cierre la app
class SesionGuardada {
  const SesionGuardada({required this.token, required this.rol, required this.usuarioId, required this.nombreCompleto, required this.nombreUsuario});
  final String token;
  final String rol;
  final String usuarioId;
  final String nombreCompleto;
  final String nombreUsuario;
}

abstract interface class RepositorioSesionGuardada {
  Future<SesionGuardada?> leer();

  Future<void> guardar(SesionGuardada sesion);

  Future<void> borrar();
}

/// Copia de lo último que respondió el servidor, para mostrarlo sin conexión
abstract interface class RepositorioRespaldoLocal {
  Future<void> guardar(String clave, Object? json);

  /// El JSON guardado y cuándo se guardó, o null si no hay nada
  Future<(Object?, DateTime)?> leer(String clave);
}
