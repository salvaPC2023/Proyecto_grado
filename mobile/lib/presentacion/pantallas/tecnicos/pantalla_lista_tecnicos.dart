import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/tecnico.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/tecnicos_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import 'pantalla_registrar_tecnico.dart';
import 'pantalla_ver_perfil_tecnico.dart';

const _paletaAvatares = [
  (fondo: Color(0xFFE0F2FE), texto: Color(0xFF0369A1)),
  (fondo: Color(0xFFE0E7FF), texto: Color(0xFF4338CA)),
  (fondo: Color(0xFFDBEAFE), texto: Color(0xFF1D4ED8)),
  (fondo: Color(0xFFBFDBFE), texto: Color(0xFF1E40AF)),
  (fondo: Color(0xFFC7D2FE), texto: Color(0xFF3730A3)),
  (fondo: Color(0xFFCFFAFE), texto: Color(0xFF0E7490)),
];

({Color fondo, Color texto}) _colorAvatar(String id) {
  return _paletaAvatares[id.hashCode.abs() % _paletaAvatares.length];
}

String _iniciales(String nombre, String apellidoPaterno) {
  final n = nombre.isNotEmpty ? nombre[0] : '';
  final a = apellidoPaterno.isNotEmpty ? apellidoPaterno[0] : '';
  return '$n$a'.toUpperCase();
}

class PantallaListaTecnicos extends ConsumerWidget {
  const PantallaListaTecnicos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoTecnicos = ref.watch(tecnicosViewModelProvider);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            _Encabezado(
              activos: estadoTecnicos.asData?.value
                      .where((t) => t.activo)
                      .length ??
                  0,
              onVolver: () => Navigator.of(context).maybePop(),
              onRegistrarTecnico: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PantallaRegistrarTecnico()),
                );
                ref.invalidate(tecnicosViewModelProvider);
              },
            ),
            Expanded(
              child: estadoTecnicos.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      mensajeDeError(error),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ColoresApp.textoOscuro),
                    ),
                  ),
                ),
                data: (tecnicos) => tecnicos.isEmpty
                    ? const Center(child: Text('No hay técnicos registrados'))
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(tecnicosViewModelProvider.notifier)
                            .recargar(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: tecnicos.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _TarjetaTecnico(
                            tecnico: tecnicos[i],
                            onVerDetalle: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PantallaVerPerfilTecnico(
                                  id: tecnicos[i].id,
                                  nombreCompleto: tecnicos[i].nombreCompleto,
                                  nombreUsuario: tecnicos[i].nombreUsuario,
                                  grupo: 'Grupo 1 - Suministros',
                                  profesion: tecnicos[i].profesion,
                                  activo: tecnicos[i].activo,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BarraNavegacionInferior(activo: SeccionNav.equipoTrabajo),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.activos,
    required this.onVolver,
    required this.onRegistrarTecnico,
  });
  final int activos;
  final VoidCallback onVolver;
  final VoidCallback onRegistrarTecnico;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      color: ColoresApp.fondo.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BotonCircular(icono: Icons.arrow_back, onPressed: onVolver),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Lista de Técnicos',
                  style: TextStyle(
                    color: ColoresApp.textoOscuro,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _BotonCircular(icono: Icons.person_add, onPressed: onRegistrarTecnico),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'PERSONAL REGISTRADO',
                style: TextStyle(
                  color: ColoresApp.textoPlaceholder,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: ColoresApp.badgeFondo,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: ColoresApp.badgeBorde),
                ),
                child: Text(
                  '$activos Técnicos a cargo',
                  style: const TextStyle(
                    color: ColoresApp.principal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonCircular extends StatelessWidget {
  const _BotonCircular({required this.icono, required this.onPressed});
  final IconData icono;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFFF1F5F9))),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icono, size: 20, color: ColoresApp.textoOscuro),
        ),
      ),
    );
  }
}

class _TarjetaTecnico extends StatelessWidget {
  const _TarjetaTecnico({required this.tecnico, required this.onVerDetalle});
  final Tecnico tecnico;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context) {
    final colores = _colorAvatar(tecnico.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colores.fondo,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _iniciales(tecnico.nombre, tecnico.apellidoPaterno),
                  style: TextStyle(
                    color: colores.texto,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: tecnico.activo
                        ? const Color(0xFF10B981)
                        : const Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tecnico.nombreCompleto,
                        style: const TextStyle(
                          color: ColoresApp.textoOscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ChipEstado(activo: tecnico.activo),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tecnico.profesion,
                  style: const TextStyle(
                    color: ColoresApp.textoSuave,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onVerDetalle,
            icon: const Icon(Icons.chevron_right, color: ColoresApp.textoPlaceholder),
          ),
        ],
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: activo ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? const Color(0xFF059669) : ColoresApp.textoPlaceholder,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
