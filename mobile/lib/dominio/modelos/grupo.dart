class Grupo {
  const Grupo({
    required this.id,
    required this.nombreDeGrupo,
    required this.cantidadTecnicos,
    this.supervisorId,
    this.supervisorNombre,
  });

  final String id;
  final String nombreDeGrupo;
  final int cantidadTecnicos;
  final String? supervisorId;
  final String? supervisorNombre;
}
