class Perfil {
  const Perfil({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.nombreUsuario,
    this.rol,
    this.profesion,
    this.grupoNombre,
    this.horarioEntrada,
    this.horarioSalida,
    this.areaDesignada,
  });

  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String nombreUsuario;

  final String? rol;
  final String? profesion;
  final String? grupoNombre;
  final String? horarioEntrada;
  final String? horarioSalida;
  final String? areaDesignada;

  bool get esSupervisor => rol == 'supervisor';

  String get nombreCompleto => [nombre, apellidoPaterno, apellidoMaterno]
      .where((p) => p != null && p.isNotEmpty)
      .join(' ');
}
