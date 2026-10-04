import 'package:flutter/material.dart';

import '../../../nucleo/fechas.dart';
import '../../../nucleo/tema.dart';
import 'formato_ot.dart';

class TiraDeDias extends StatelessWidget {
  const TiraDeDias({super.key, required this.seleccionada, required this.onSeleccionar});
  final DateTime seleccionada;
  final ValueChanged<DateTime> onSeleccionar;

  static const _diasAlrededor = 2;

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final hoy = hoySinHora();
    final dias = [
      for (var i = -_diasAlrededor; i <= _diasAlrededor; i++) hoy.add(Duration(days: i)),
    ];

    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final dia in dias)
            _ChipDia(
              arriba: nombreMes(dia),
              centro: '${dia.day}',
              abajo: _mismoDia(dia, hoy) ? 'Hoy' : nombreDia(dia),
              seleccionado: _mismoDia(dia, seleccionada),
              onTap: () => onSeleccionar(dia),
            ),
        ],
      ),
    );
  }
}

class _ChipDia extends StatelessWidget {
  const _ChipDia({
    required this.arriba,
    required this.centro,
    required this.abajo,
    required this.seleccionado,
    required this.onTap,
  });
  final String arriba;
  final String centro;
  final String abajo;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorTexto = seleccionado ? Colors.white : ColoresApp.textoOscuro;
    final colorSuave = seleccionado ? Colors.white70 : ColoresApp.textoPlaceholder;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: seleccionado ? 70 : 58,
      height: seleccionado ? 96 : 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: seleccionado ? ColoresApp.principal : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: seleccionado
            ? [
                BoxShadow(
                  color: ColoresApp.principal.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(arriba, style: TextStyle(color: colorSuave, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(
                centro,
                style: TextStyle(
                  color: colorTexto,
                  fontSize: seleccionado ? 22 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(abajo, style: TextStyle(color: colorSuave, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
