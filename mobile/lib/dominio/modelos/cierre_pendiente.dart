/// Cierre de un paso que se registró en el celular y todavía no llegó al servidor.
/// El id se genera en el celular: si se reenvía, el servidor lo reconoce y no lo duplica
class CierrePendiente {
  const CierrePendiente({
    required this.id,
    required this.usuarioId,
    required this.otId,
    required this.pasoId,
    required this.ejecutado,
    required this.tiempoRealTrabajado,
    required this.descripcion,
    required this.fechaHora,
    this.tituloOt = '',
    this.descripcionPaso = '',
    this.motivoRechazo,
  });

  final String id;
  // la cola solo se envía con la sesión de quien registró el cierre
  final String usuarioId;
  final String otId;
  final String pasoId;
  final bool ejecutado;
  final double tiempoRealTrabajado;
  final String descripcion;
  // hora en que el técnico cerró el paso, no la hora en que llega al servidor
  final DateTime fechaHora;
  // para mostrarlo en los avisos sin tener que buscar la OT
  final String tituloOt;
  final String descripcionPaso;
  // si el servidor lo rechazó (por ejemplo, la OT ya estaba cerrada), no se reintenta
  final String? motivoRechazo;

  bool get rechazado => motivoRechazo != null;

  CierrePendiente rechazar(String motivo) => CierrePendiente(
        id: id,
        usuarioId: usuarioId,
        otId: otId,
        pasoId: pasoId,
        ejecutado: ejecutado,
        tiempoRealTrabajado: tiempoRealTrabajado,
        descripcion: descripcion,
        fechaHora: fechaHora,
        tituloOt: tituloOt,
        descripcionPaso: descripcionPaso,
        motivoRechazo: motivo,
      );
}
