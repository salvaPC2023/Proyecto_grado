import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/supervisores_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';

/// Turnos del departamento; el grupo del supervisor trabaja en uno de ellos
const turnos = {
  'Turno 1 (23:00 - 07:00)': ('23:00', '07:00'),
  'Turno 2 (07:00 - 15:00)': ('07:00', '15:00'),
  'Turno 3 (15:00 - 23:00)': ('15:00', '23:00'),
};

class PantallaRegistrarSupervisor extends ConsumerStatefulWidget {
  const PantallaRegistrarSupervisor({super.key});

  @override
  ConsumerState<PantallaRegistrarSupervisor> createState() => _PantallaRegistrarSupervisorState();
}

class _PantallaRegistrarSupervisorState extends ConsumerState<PantallaRegistrarSupervisor> {
  final _nombre = TextEditingController();
  final _apellidoPaterno = TextEditingController();
  final _apellidoMaterno = TextEditingController();
  final _usuario = TextEditingController();
  final _grupo = TextEditingController();
  String _turno = turnos.keys.elementAt(1);
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _apellidoPaterno, _apellidoMaterno, _usuario, _grupo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final mensajero = ScaffoldMessenger.of(context);
    if ([_nombre, _apellidoPaterno, _usuario, _grupo].any((c) => c.text.trim().isEmpty)) {
      mensajero.showSnackBar(const SnackBar(content: Text('Completa los campos obligatorios')));
      return;
    }

    setState(() => _guardando = true);
    final (entrada, salida) = turnos[_turno]!;
    try {
      await ref.read(supervisoresViewModelProvider.notifier).crear(
            nombre: _nombre.text.trim(),
            apellidoPaterno: _apellidoPaterno.text.trim(),
            apellidoMaterno: _apellidoMaterno.text.trim().isEmpty ? null : _apellidoMaterno.text.trim(),
            nombreUsuario: _usuario.text.trim(),
            nombreDeGrupo: _grupo.text.trim(),
            horarioEntrada: entrada,
            horarioSalida: salida,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      mensajero.showSnackBar(const SnackBar(content: Text('Supervisor registrado')));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            _Encabezado(onVolver: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(21, 8, 21, 110),
                children: [
                  _Campo(etiqueta: 'Nombre *', controlador: _nombre, indicativo: 'Ej. Ana'),
                  _Campo(etiqueta: 'Apellido Paterno *', controlador: _apellidoPaterno, indicativo: 'Ej. Rojas'),
                  _Campo(etiqueta: 'Apellido Materno', controlador: _apellidoMaterno, indicativo: 'Ej. Salazar'),
                  _Campo(etiqueta: 'Nombre de Usuario *', controlador: _usuario, indicativo: 'arojas_sup'),
                  _Campo(etiqueta: 'Nombre del Grupo *', controlador: _grupo, indicativo: 'Ej. Grupo Suministros'),
                  const _Etiqueta('Turno del grupo *'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ColoresApp.campoFondo,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColoresApp.campoBorde),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _turno,
                        isExpanded: true,
                        items: [for (final t in turnos.keys) DropdownMenuItem(value: t, child: Text(t))],
                        onChanged: (t) => setState(() => _turno = t ?? _turno),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'La contraseña inicial es la del sistema; el supervisor deberá cambiarla.',
                    style: TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  _BotonGuardar(onPressed: _guardando ? null : _guardar, cargando: _guardando),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.supervisores),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onVolver});
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(side: BorderSide(color: Color(0xFFF1F5F9))),
              elevation: 2,
              shadowColor: Colors.black12,
              child: IconButton(
                tooltip: 'Volver',
                onPressed: onVolver,
                icon: const Icon(Icons.arrow_back, size: 20, color: ColoresApp.textoOscuro),
              ),
            ),
          ),
          const Text(
            'Registrar Supervisor',
            style: TextStyle(color: ColoresApp.textoOscuro, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(color: ColoresApp.textoLabel, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.etiqueta, required this.controlador, required this.indicativo});
  final String etiqueta;
  final TextEditingController controlador;
  final String indicativo;

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColoresApp.campoBorde),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Etiqueta(etiqueta),
          TextField(
            controller: controlador,
            style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14),
            decoration: InputDecoration(
              hintText: indicativo,
              hintStyle: const TextStyle(color: ColoresApp.textoPlaceholder),
              filled: true,
              fillColor: ColoresApp.campoFondo,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: borde,
              enabledBorder: borde,
              focusedBorder: borde.copyWith(borderSide: const BorderSide(color: ColoresApp.principal, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonGuardar extends StatelessWidget {
  const _BotonGuardar({required this.onPressed, required this.cargando});
  final VoidCallback? onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [ColoresApp.gradienteInicio, ColoresApp.gradienteFin]),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: cargando
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Guardar Supervisor',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check, size: 16, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
