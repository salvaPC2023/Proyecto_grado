import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: reemplazar por el provider real de HU-02 (funcionalidades/acceso_roles)
// import '../../../nucleo/di.dart';

// Coincide con profesion_enum de Query.txt: ('electrico','mecanico','electromecanico')
enum Profesion { electrico, mecanico, electromecanico }

extension _ProfesionLabel on Profesion {
  String get etiqueta => switch (this) {
        Profesion.electrico => 'Eléctrico',
        Profesion.mecanico => 'Mecánico',
        Profesion.electromecanico => 'Electromecánico',
      };
}

class PantallaCrearTecnico extends ConsumerStatefulWidget {
  const PantallaCrearTecnico({super.key});

  @override
  ConsumerState<PantallaCrearTecnico> createState() =>
      _PantallaCrearTecnicoState();
}

class _PantallaCrearTecnicoState extends ConsumerState<PantallaCrearTecnico> {
  final _controladorNombre = TextEditingController();
  final _controladorApellidoPaterno = TextEditingController();
  final _controladorApellidoMaterno = TextEditingController();
  final _controladorUsuario = TextEditingController();
  final _claveFormulario = GlobalKey<FormState>();

  // TODO: cargar la lista real de grupos (endpoint de Grupo) en vez de este placeholder
  String? _grupoSeleccionadoId;
  Profesion? _profesionSeleccionada;

  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorApellidoPaterno.dispose();
    _controladorApellidoMaterno.dispose();
    _controladorUsuario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_claveFormulario.currentState!.validate()) return;
    if (_grupoSeleccionadoId == null || _profesionSeleccionada == null) {
      setState(() => _error = 'Selecciona grupo y profesión');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // TODO: llamar al caso de uso real de crear tecnico (HU-02)
      // await ref.read(controladorTecnicosProvider.notifier).crearTecnico(
      //   nombre: _controladorNombre.text.trim(),
      //   apellidoPaterno: _controladorApellidoPaterno.text.trim(),
      //   apellidoMaterno: _controladorApellidoMaterno.text.trim().isEmpty
      //       ? null
      //       : _controladorApellidoMaterno.text.trim(),
      //   nombreUsuario: _controladorUsuario.text.trim(),
      //   grupoId: _grupoSeleccionadoId!,
      //   profesion: _profesionSeleccionada!,
      // );
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = e.toString().contains('409')
            ? 'El nombre de usuario ya está en uso'
            : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo técnico')),
      body: Form(
        key: _claveFormulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _controladorNombre,
              decoration: const InputDecoration(
                  labelText: 'Nombre', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              enabled: !_cargando,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controladorApellidoPaterno,
              decoration: const InputDecoration(
                  labelText: 'Apellido paterno',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              enabled: !_cargando,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controladorApellidoMaterno,
              decoration: const InputDecoration(
                  labelText: 'Apellido materno (opcional)',
                  border: OutlineInputBorder()),
              enabled: !_cargando,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controladorUsuario,
              decoration: const InputDecoration(
                  labelText: 'Nombre de usuario', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
              enabled: !_cargando,
            ),
            const SizedBox(height: 16),
            // TODO: reemplazar por un DropdownButtonFormField con los grupos reales
            DropdownButtonFormField<String>(
              value: _grupoSeleccionadoId,
              decoration: const InputDecoration(
                  labelText: 'Grupo', border: OutlineInputBorder()),
              items: const [], // TODO: llenar con los grupos del supervisor
              onChanged: (v) => setState(() => _grupoSeleccionadoId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Profesion>(
              value: _profesionSeleccionada,
              decoration: const InputDecoration(
                  labelText: 'Profesión', border: OutlineInputBorder()),
              items: Profesion.values
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p.etiqueta)))
                  .toList(),
              onChanged: (v) => setState(() => _profesionSeleccionada = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 8),
            // TODO: este valor debe coincidir con default_technician_password en configuracion.py
            const Text(
              'La contraseña inicial será COLBO2026.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _cargando ? null : _enviar,
                child: _cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear técnico'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
