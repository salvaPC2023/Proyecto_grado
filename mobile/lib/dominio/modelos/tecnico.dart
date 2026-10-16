class Tecnico {
  const Tecnico({
    required this.id,
    required this.usuarioId,
    required this.grupoId,
    required this.profesion,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.nombreUsuario,
    required this.activo,
    this.grupoNombre,
    this.passwordInicial,
  });

  final String id;
  final String usuarioId;
  final String grupoId;
  final String profesion;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String nombreUsuario;
  final bool activo;
  final String? grupoNombre;
  // solo viene en la respuesta al registrarlo, para mostrarla en el diálogo de datos de acceso
  final String? passwordInicial;

  String get nombreCompleto => [nombre, apellidoPaterno, apellidoMaterno]
      .where((p) => p != null && p.isNotEmpty)
      .join(' ');
}
