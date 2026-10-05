import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/ordenes_trabajo_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import 'componentes_ot.dart';
import 'formato_ot.dart';
import 'pantalla_cierre_paso.dart';

class PantallaDetalleOt extends ConsumerWidget {
  const PantallaDetalleOt({super.key, required this.otId});
  final String otId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(detalleOtProvider(otId));
    final esTecnico = !(ref.watch(sesionProvider)?.esSupervisor ?? false);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoOts(titulo: 'Detalle de OT'),
            Expanded(
              child: estado.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => MensajeCentrado(
                  icono: Icons.cloud_off,
                  texto: mensajeDeError(error),
                  accion: 'Reintentar',
                  onAccion: () => ref.invalidate(detalleOtProvider(otId)),
                ),
                data: (ot) => RefreshIndicator(
                  onRefresh: () => ref.refresh(detalleOtProvider(otId).future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    children: [
                      _Resumen(ot: ot),
                      const SizedBox(height: 14),
                      if (ot.pm01Total > 0) ...[
                        _AvancePm01(cerrados: ot.pm01Cerrados, total: ot.pm01Total),
                        const SizedBox(height: 14),
                      ],
                      const Text(
                        'Pasos',
                        style: TextStyle(
                          color: ColoresApp.textoOscuro,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final paso in ot.pasos)
                        _TarjetaPaso(
                          otId: ot.id,
                          paso: paso,
                          puedeCerrar: esTecnico &&
                              paso.esPm01 &&
                              !paso.cerrado &&
                              ot.estatus != 'cerrada',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.agenda),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.ot});
  final OrdenTrabajo ot;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              ChipEtiqueta(estilo: estiloEstatus(ot.estatus)),
              const SizedBox(width: 6),
              ChipEtiqueta(estilo: estiloPrioridad(ot.prioridad), conBorde: true),
              const Spacer(),
              Text(
                ot.tipoDeOrden,
                style: const TextStyle(
                  color: ColoresApp.principal,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ot.titulo,
            style: const TextStyle(
              color: ColoresApp.textoOscuro,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (ot.ubicacion != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: ColoresApp.principal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ot.ubicacion!.ruta,
                    style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            ot.descripcion,
            style: const TextStyle(color: ColoresApp.textoLabel, fontSize: 14, height: 1.4),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _Dato(
            icono: Icons.play_circle_outline,
            etiqueta: 'Inicio planificado',
            valor: '${formatoFecha(ot.fechaInicPlanif)} · ${formatoHora(ot.fechaInicPlanif)}',
          ),
          _Dato(
            icono: Icons.flag_outlined,
            etiqueta: 'Fin planificado',
            valor: '${formatoFecha(ot.fechaFinPlanif)} · ${formatoHora(ot.fechaFinPlanif)}',
          ),
          _Dato(
            icono: Icons.schedule,
            etiqueta: 'Horas planificadas',
            valor: formatoHoras(ot.horasPlanificadas),
          ),
          _Dato(
            icono: Icons.power_settings_new,
            etiqueta: 'Estado del equipo',
            valor: ot.estatusEquipo ? 'En funcionamiento' : 'Detenido para intervención',
          ),
          if (ot.fechaCierre != null)
            _Dato(
              icono: Icons.check_circle_outline,
              etiqueta: 'Cerrada el',
              valor: '${formatoFecha(ot.fechaCierre!)} · ${formatoHora(ot.fechaCierre!)}',
            ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.etiqueta, required this.valor});
  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 18, color: ColoresApp.principal),
          const SizedBox(width: 8),
          Text(
            '$etiqueta: ',
            style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 13),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: ColoresApp.textoOscuro,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvancePm01 extends StatelessWidget {
  const _AvancePm01({required this.cerrados, required this.total});
  final int cerrados;
  final int total;

  @override
  Widget build(BuildContext context) {
    final completo = cerrados == total;
    final color = completo ? const Color(0xFF047857) : const Color(0xFFD97706);
    final pendientes = total - cerrados;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Avance de pasos PM01',
                  style: TextStyle(
                    color: ColoresApp.textoOscuro,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$cerrados / $total',
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : cerrados / total,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            completo
                ? 'Todos los pasos PM01 están cerrados'
                : '$pendientes paso${pendientes == 1 ? '' : 's'} PM01 pendiente${pendientes == 1 ? '' : 's'}',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPaso extends StatelessWidget {
  const _TarjetaPaso({required this.otId, required this.paso, required this.puedeCerrar});
  final String otId;
  final PasoOt paso;
  final bool puedeCerrar;

  Future<void> _abrirCierre(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    final registrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PantallaCierrePaso(otId: otId, paso: paso)),
    );
    if (registrado == true) {
      mensajero.showSnackBar(const SnackBar(content: Text('Cierre registrado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cierre = paso.cierre;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paso.esPm01 ? Colors.white : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: paso.esPm01 ? const Color(0xFFF1F5F9) : ColoresApp.badgeBorde,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: ColoresApp.badgeFondo,
                child: Text(
                  '${paso.numeroPaso}',
                  style: const TextStyle(
                    color: ColoresApp.principal,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ChipEtiqueta(
                estilo: paso.esPm01
                    ? const EstiloEtiqueta('PM01', Colors.white, ColoresApp.principal)
                    : const EstiloEtiqueta('PMNN', ColoresApp.principal, ColoresApp.badgeFondo),
                conBorde: !paso.esPm01,
              ),
              const Spacer(),
              _EstadoPaso(paso: paso),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            paso.descripcion,
            style: const TextStyle(
              color: ColoresApp.textoOscuro,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (paso.esPm01 && paso.horasPlanificadas != null) ...[
            const SizedBox(height: 4),
            Text(
              'Planificado: ${formatoHoras(paso.horasPlanificadas!)}',
              style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12),
            ),
          ],
          if (cierre != null) _ResumenCierre(cierre: cierre),
          if (puedeCerrar) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _abrirCierre(context),
                icon: const Icon(Icons.task_alt),
                label: const Text('Registrar cierre'),
                style: FilledButton.styleFrom(
                  backgroundColor: ColoresApp.principal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoPaso extends StatelessWidget {
  const _EstadoPaso({required this.paso});
  final PasoOt paso;

  @override
  Widget build(BuildContext context) {
    if (!paso.esPm01) {
      return const Text(
        'Informativo',
        style: TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 12),
      );
    }
    return ChipEtiqueta(
      estilo: paso.cerrado
          ? const EstiloEtiqueta('Cerrado', Color(0xFF047857), Color(0xFFD1FAE5))
          : const EstiloEtiqueta('Pendiente', Color(0xFFD97706), Color(0xFFFEF3C7)),
    );
  }
}

class _ResumenCierre extends StatelessWidget {
  const _ResumenCierre({required this.cierre});
  final CierrePaso cierre;

  @override
  Widget build(BuildContext context) {
    final ejecutado = cierre.resultadoTrabajo == 'ejecutado';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ejecutado ? 'Ejecutado' : 'No ejecutado'} · '
            'Real: ${formatoHoras(cierre.tiempoRealTrabajado)} · '
            '${formatoFecha(cierre.fechaHoraNotificacion)} ${formatoHora(cierre.fechaHoraNotificacion)}',
            style: const TextStyle(
              color: Color(0xFF047857),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cierre.descripcionTrabajoRealizado,
            style: const TextStyle(color: ColoresApp.textoLabel, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }
}
