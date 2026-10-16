import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';
import '../../nucleo/validacion_password.dart';

/// Lista de reglas de la contraseña que se marca en verde mientras se escribe
class ChecklistPassword extends StatelessWidget {
  const ChecklistPassword({super.key, required this.controlador});
  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) {
    // se reconstruye solo cada vez que cambia el texto del controlador
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controlador,
      builder: (context, valor, _) {
        if (valor.text.isEmpty) return const SizedBox.shrink(); // nada que mostrar
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final regla in reglasPassword)
              _ItemRegla(
                texto: regla.descripcion,
                cumplida: regla.seCumple(valor.text),
              ),
          ],
        );
      },
    );
  }
}

class _ItemRegla extends StatelessWidget {
  const _ItemRegla({required this.texto, required this.cumplida});
  final String texto;
  final bool cumplida;

  @override
  Widget build(BuildContext context) {
    // condición ? siVerdadero : siFalso  (como "a if c else b" en Python)
    final color = cumplida ? const Color(0xFF10B981) : ColoresApp.textoPlaceholder;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            cumplida ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
