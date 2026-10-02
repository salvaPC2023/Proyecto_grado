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

  String get nombreCompleto => [nombre, apellidoPaterno, apellidoMaterno]
      .where((p) => p != null && p.isNotEmpty)
      .join(' ');
}
