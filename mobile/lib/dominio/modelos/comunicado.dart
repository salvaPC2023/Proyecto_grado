enum CategoriaComunicado { seguridad, mantenimiento, produccion, general }

class Comunicado {
  const Comunicado({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.tieneImagen,
    required this.personal,
    required this.fechaEnvio,
    required this.fechaExpiracion,
    required this.autorNombre,
    this.texto,
    this.destinatarioNombre,
  });

  final String id;
  final String titulo;
  final String? texto;
  final CategoriaComunicado categoria;
  final bool tieneImagen;
  // false = general para todo el grupo
  final bool personal;
  final DateTime fechaEnvio;
  final DateTime fechaExpiracion;
  final String autorNombre;
  // solo en los personales: a quién se envió (lo ve el supervisor)
  final String? destinatarioNombre;
}

/// Datos de un comunicado nuevo; sin técnico es general para todo el grupo
class ComunicadoNuevo {
  const ComunicadoNuevo({
    required this.titulo,
    required this.categoria,
    required this.fechaExpiracion,
    this.texto,
    this.tecnicoId,
    this.imagen,
    this.nombreImagen,
  });

  final String titulo;
  final CategoriaComunicado categoria;
  final DateTime fechaExpiracion;
  final String? texto;
  final String? tecnicoId;
  final List<int>? imagen;
  final String? nombreImagen;
}
