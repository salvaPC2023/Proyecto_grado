import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/sesion.dart';
import '../../nucleo/tema.dart';
import '../pantallas/ordenes_trabajo/pantalla_mis_ots.dart';
import '../pantallas/ordenes_trabajo/pantalla_nueva_ot.dart';
import '../pantallas/ordenes_trabajo/pantalla_ots_grupo.dart';
import '../pantallas/supervisores/pantalla_lista_supervisores.dart';
import '../pantallas/tecnicos/pantalla_lista_tecnicos.dart';

enum SeccionNav { inicio, agenda, ordenesTrabajo, equipoTrabajo }

const _colorIcono = ColoresApp.principal;

class BarraNavegacionInferior extends ConsumerWidget {
  const BarraNavegacionInferior({super.key, required this.activo});
  final SeccionNav activo;

  void _irA(BuildContext context, Widget pantalla) {
    final navegador = Navigator.of(context);
    navegador.popUntil((ruta) => ruta.isFirst);
    navegador.push(MaterialPageRoute(builder: (_) => pantalla));
  }

  void _irAlInicio(BuildContext context) {
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final esSupervisor = sesion?.esSupervisor ?? false;
    final esAdministrador = sesion?.esAdministrador ?? false;
    final inicio = _ItemNav(
      icono: Icons.home_rounded,
      activo: activo == SeccionNav.inicio,
      onTap: () => _irAlInicio(context),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 26, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ColoresApp.navFondo,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: ColoresApp.navBorde),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: esAdministrador
            // el administrador solo gestiona supervisores
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  inicio,
                  _ItemNav(
                    icono: Icons.groups_outlined,
                    activo: activo == SeccionNav.equipoTrabajo,
                    onTap: () =>
                        _irA(context, const PantallaListaSupervisores()),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  inicio,
                  _ItemNav(
                    icono: Icons.calendar_today_outlined,
                    activo: activo == SeccionNav.agenda,
                    onTap: () => _irA(
                      context,
                      esSupervisor
                          ? const PantallaOtsGrupo()
                          : const PantallaMisOts(),
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
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 2),
        ),
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
  const _ItemNav({
    required this.icono,
    required this.activo,
    required this.onTap,
  });
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
          color: activo
              ? _colorIcono.withValues(alpha: 0.12)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icono, size: 20, color: _colorIcono),
      ),
    );
  }
}
