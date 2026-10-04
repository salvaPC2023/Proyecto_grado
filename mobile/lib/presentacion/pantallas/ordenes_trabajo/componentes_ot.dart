import 'package:flutter/material.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../nucleo/tema.dart';
import 'formato_ot.dart';


class EncabezadoOts extends StatelessWidget {
  const EncabezadoOts({super.key, required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back, color: ColoresApp.textoOscuro),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoOscuro,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class TarjetaOt extends StatelessWidget {
  const TarjetaOt({super.key, required this.ot, this.nombreTecnico, this.onTap});
  final OrdenTrabajo ot;

  final String? nombreTecnico;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mismoDia = ot.fechaInicPlanif.year == ot.fechaFinPlanif.year &&
        ot.fechaInicPlanif.month == ot.fechaFinPlanif.month &&
        ot.fechaInicPlanif.day == ot.fechaFinPlanif.day;
    final fechas = mismoDia
        ? '${formatoFecha(ot.fechaInicPlanif)} · ${formatoHora(ot.fechaInicPlanif)}–${formatoHora(ot.fechaFinPlanif)}'
        : '${formatoFecha(ot.fechaInicPlanif)} al ${formatoFecha(ot.fechaFinPlanif)}';

    final tarjeta = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0F1E3A8A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ot.ubicacion?.resumen ?? 'Ubicación',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoPlaceholder,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ChipEtiqueta(estilo: estiloEstatus(ot.estatus)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ot.titulo,
            style: const TextStyle(
              color: ColoresApp.textoOscuro,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ot.tipoDeOrden} · $fechas',
            style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
          ),
          if (nombreTecnico != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: ColoresApp.principal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    nombreTecnico!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ColoresApp.principal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                formatoHoras(ot.horasPlanificadas),
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ChipEtiqueta(estilo: estiloPrioridad(ot.prioridad), conBorde: true),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return tarjeta;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: tarjeta,
      ),
    );
  }
}

class MensajeCentrado extends StatelessWidget {
  const MensajeCentrado({
    super.key,
    required this.icono,
    required this.texto,
    this.accion,
    this.onAccion,
  });
  final IconData icono;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: ColoresApp.textoPlaceholder),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 15),
            ),
            if (accion != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAccion, child: Text(accion!)),
            ],
          ],
        ),
      ),
    );
  }
}
