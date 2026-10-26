class UsuarioImportado {
  const UsuarioImportado({required this.fila, required this.nombreCompleto, required this.nombreUsuario, required this.rol});

  final int fila;
  final String nombreCompleto;
  final String nombreUsuario;
  final String rol;
}

class AvisoImportacion {
  const AvisoImportacion({required this.fila, required this.dato, required this.motivo});

  final int fila;
  final String dato;
  final String motivo;
}

class ResultadoImportacion {
  const ResultadoImportacion({
    required this.usuariosCreados,
    required this.ubicacionesCreadas,
    required this.omitidos,
    required this.errores,
    this.otsCreadas = 0,
  });

  final List<UsuarioImportado> usuariosCreados;
  final int ubicacionesCreadas;
  final int otsCreadas; // solo en la importación del supervisor
  final List<AvisoImportacion> omitidos;
  final List<AvisoImportacion> errores;
}
