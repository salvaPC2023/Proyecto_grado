import 'package:flutter/material.dart';


class EstiloEtiqueta {
  const EstiloEtiqueta(this.texto, this.color, this.fondo);
  final String texto;
  final Color color;
  final Color fondo;
}

EstiloEtiqueta estiloEstatus(String estatus) => switch (estatus) {
      'asignada' => const EstiloEtiqueta('Asignada', Color(0xFF475569), Color(0xFFF1F5F9)),
      'en_progreso' => const EstiloEtiqueta('En proceso', Color(0xFF1D4ED8), Color(0xFFDBEAFE)),
      'cerrada' => const EstiloEtiqueta('Finalizada', Color(0xFF047857), Color(0xFFD1FAE5)),
      _ => EstiloEtiqueta(estatus, const Color(0xFF475569), const Color(0xFFF1F5F9)),
    };

const etiquetasPrioridad = {1: 'Urgente', 2: 'Alta', 3: 'Normal', 4: 'Baja'};

EstiloEtiqueta estiloPrioridad(int prioridad) => switch (prioridad) {
      1 => const EstiloEtiqueta('Urgente', Color(0xFFE11D48), Color(0xFFFFE4E6)),
      2 => const EstiloEtiqueta('Alta', Color(0xFFD97706), Color(0xFFFEF3C7)),
      3 => const EstiloEtiqueta('Normal', Color(0xFF0E7490), Color(0xFFCFFAFE)),
      _ => const EstiloEtiqueta('Baja', Color(0xFF475569), Color(0xFFF1F5F9)),
    };

const _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

String nombreMes(DateTime f) => _meses[f.month - 1];
String nombreDia(DateTime f) => _dias[f.weekday - 1];
String dosDigitos(int n) => n.toString().padLeft(2, '0');

String formatoFecha(DateTime f) => '${dosDigitos(f.day)} ${nombreMes(f)} ${f.year}';

String formatoHora(DateTime f) => '${dosDigitos(f.hour)}:${dosDigitos(f.minute)}';

String formatoHoras(double horas) {
  final numero = horas == horas.roundToDouble()
      ? horas.toInt().toString()
      : horas.toStringAsFixed(1);
  return '$numero ${horas == 1 ? 'Hora' : 'Horas'}';
}

class ChipEtiqueta extends StatelessWidget {
  const ChipEtiqueta({super.key, required this.estilo, this.conBorde = false});
  final EstiloEtiqueta estilo;
  final bool conBorde;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estilo.fondo,
        borderRadius: BorderRadius.circular(9999),
        border: conBorde ? Border.all(color: estilo.color.withValues(alpha: 0.35)) : null,
      ),
      child: Text(
        estilo.texto,
        style: TextStyle(color: estilo.color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
