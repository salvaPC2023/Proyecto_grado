/// Hoy a las 00:00, para comparar o pedir solo el dia.
DateTime hoySinHora() {
  final ahora = DateTime.now();
  return DateTime(ahora.year, ahora.month, ahora.day);
}
