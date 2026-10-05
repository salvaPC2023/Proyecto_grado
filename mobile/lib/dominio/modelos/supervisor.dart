class Supervisor {
  const Supervisor({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.nombreUsuario,
    required this.activo,
    required this.horarioEntrada,
    required this.horarioSalida,
    this.grupoNombre,
  });

  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String nombreUsuario;
  final bool activo;
  final String horarioEntrada;
  final String horarioSalida;
  final String? grupoNombre;

  String get nombreCompleto => [nombre, apellidoPaterno, apellidoMaterno]
      .where((p) => p != null && p.isNotEmpty)
      .join(' ');

  /// "07:00 - 15:00" (el backend envía las horas con segundos)
  String get horario => '${horarioEntrada.substring(0, 5)} - ${horarioSalida.substring(0, 5)}';
}
