import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/sesion.dart';
import '../../nucleo/tema.dart';
import '../pantallas/autenticacion/pantalla_inicio_sesion.dart';

/// El administrador no tiene pantalla de inicio: cada pantalla suya permite cerrar sesión
class EncabezadoAdministrador extends ConsumerWidget {
  const EncabezadoAdministrador({
    super.key,
    required this.titulo,
    required this.iconoAccion,
    required this.textoAccion,
    required this.onAccion,
  });

  final String titulo;
  final IconData iconoAccion;
  final String textoAccion;
  final VoidCallback onAccion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          BotonCircular(
            icono: Icons.logout,
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ref.read(sesionProvider.notifier).cerrarSesion();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
                (ruta) => false,
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          BotonCircular(icono: iconoAccion, tooltip: textoAccion, onPressed: onAccion),
        ],
      ),
    );
  }
}

class BotonCircular extends StatelessWidget {
  const BotonCircular({super.key, required this.icono, required this.tooltip, required this.onPressed});
  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFFF1F5F9))),
      elevation: 2,
      shadowColor: Colors.black12,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icono, size: 20, color: ColoresApp.textoOscuro),
      ),
    );
  }
}

/// Tarjeta blanca de las listas del administrador
class TarjetaAdministrador extends StatelessWidget {
  const TarjetaAdministrador({super.key, required this.titulo, required this.detalle, required this.acciones, this.onTap});
  final String titulo;
  final String detalle;
  final List<Widget> acciones;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(detalle, style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12)),
                  ],
                ),
              ),
              ...acciones,
            ],
          ),
        ),
      ),
    );
  }
}
