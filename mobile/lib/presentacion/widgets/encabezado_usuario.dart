import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/sesion.dart';
import '../viewmodels/cola_cierres_vm.dart';
import '../../nucleo/tema.dart';
import '../pantallas/autenticacion/pantalla_inicio_sesion.dart';
import '../pantallas/perfil/pantalla_mi_perfil.dart';

/// Encabezado comun de los tres roles
class EncabezadoUsuario extends ConsumerWidget {
  const EncabezadoUsuario({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final imagenAvatar = sesion?.imagenAvatar ?? 'assets/images/icono_tecnico.png';
    final rol = sesion?.etiquetaRol ?? '';
    final nombre = sesion?.nombreCompleto ?? '';

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PantallaMiPerfil()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF60A5FA), width: 2),
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(imagenAvatar),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Bienvenido!',
                style: TextStyle(
                  color: ColoresApp.textoSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$rol $nombre',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: () => _cerrarSesion(context, ref),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Icon(Icons.logout,
                size: 20, color: ColoresApp.textoOscuro),
          ),
        ),
      ],
    );
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    // los cierres guardados sin conexión no se pierden: se envían cuando la misma persona vuelve a entrar
    final pendientes = ref.read(misCierresEnColaProvider).where((c) => !c.rechazado).length;
    if (pendientes > 0) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: const Text('Cierres sin enviar'),
          content: Text(
            pendientes == 1
                ? 'Tienes 1 cierre que aún no llegó al servidor. Se enviará cuando vuelvas a iniciar sesión con tu usuario.'
                : 'Tienes $pendientes cierres que aún no llegaron al servidor. Se enviarán cuando vuelvas a iniciar sesión con tu usuario.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Cerrar sesión')),
          ],
        ),
      );
      if (confirmado != true || !context.mounted) return;
    }
    ref.read(sesionProvider.notifier).cerrarSesion();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
      (ruta) => false, // borra todo el historial: con "atrás" no se vuelve al sistema
    );
  }
}