import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/sesion.dart';
import '../../nucleo/tema.dart';
import '../pantallas/inicio/pantalla_inicio.dart';
import '../pantallas/ordenes_trabajo/pantalla_mis_ots.dart';
import '../pantallas/ordenes_trabajo/pantalla_nueva_ot.dart';
import '../pantallas/ordenes_trabajo/pantalla_ots_grupo.dart';
import '../pantallas/tecnicos/pantalla_lista_tecnicos.dart';

enum SeccionNav { inicio, agenda, ordenesTrabajo, equipoTrabajo }

const _colorIcono = ColoresApp.principal;

// El calendario abre las OTs por dia de cada rol: las propias del Tecnico
// o las del grupo del Supervisor. El boton "+" central (Nueva OT)
// y el de gestion de tecnicos (grupo) solo los ve el Supervisor.
// TODO: definir que abre el icono de "Ordenes de Trabajo" (portapapeles).
class BarraNavegacionInferior extends ConsumerWidget {
  const BarraNavegacionInferior({super.key, required this.activo});
  final SeccionNav activo;

  void _irA(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esSupervisor = ref.watch(sesionProvider)?.esSupervisor ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 26, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ColoresApp.navFondo,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: ColoresApp.navBorde),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ItemNav(
              icono: Icons.home_rounded,
              activo: activo == SeccionNav.inicio,
              onTap: () => _irA(context, const PantallaInicio()),
            ),
            _ItemNav(
              icono: Icons.calendar_today_outlined,
              activo: activo == SeccionNav.agenda,
              onTap: () => _irA(
                context,
                esSupervisor ? const PantallaOtsGrupo() : const PantallaMisOts(),
              ),
            ),
            if (esSupervisor)
              _BotonAccionRapida(
                onTap: () => _irA(context, const PantallaNuevaOt()),
              ),
            _ItemNav(
              icono: Icons.assignment_outlined,
              activo: activo == SeccionNav.ordenesTrabajo,
              onTap: () {},
            ),
            // Gestion de tecnicos (listar, registrar, deshabilitar): solo Supervisor.
            // El backend ademas responde 403 a un Tecnico en /tecnicos.
            if (esSupervisor)
              _ItemNav(
                icono: Icons.groups_outlined,
                activo: activo == SeccionNav.equipoTrabajo,
                onTap: () => _irA(context, const PantallaListaTecnicos()),
              ),
          ],
        ),
      ),
    );
  }
}

class _BotonAccionRapida extends StatelessWidget {
  const _BotonAccionRapida({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Material(
        color: _colorIcono,
        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
        elevation: 6,
        shadowColor: _colorIcono.withValues(alpha: 0.5),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add, size: 26, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav({required this.icono, required this.activo, required this.onTap});
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo ? _colorIcono.withValues(alpha: 0.12) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icono, size: 20, color: _colorIcono),
      ),
    );
  }
}
