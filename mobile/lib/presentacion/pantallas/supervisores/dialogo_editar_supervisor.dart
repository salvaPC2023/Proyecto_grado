import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/grupo.dart';
import '../../../dominio/modelos/supervisor.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/supervisores_vm.dart';
import 'pantalla_registrar_supervisor.dart' show turnos;

/// Administrador: corrige turno, área y grupo de un supervisor. Devuelve true si guardó
Future<bool?> mostrarDialogoEditarSupervisor(
  BuildContext context, {
  required Supervisor supervisor,
  required List<Grupo> grupos,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _DialogoEditarSupervisor(supervisor: supervisor, grupos: grupos),
  );
}

class _DialogoEditarSupervisor extends ConsumerStatefulWidget {
  const _DialogoEditarSupervisor({required this.supervisor, required this.grupos});
  final Supervisor supervisor;
  final List<Grupo> grupos;

  @override
  ConsumerState<_DialogoEditarSupervisor> createState() => _DialogoEditarSupervisorState();
}

class _DialogoEditarSupervisorState extends ConsumerState<_DialogoEditarSupervisor> {
  late final _area = TextEditingController(text: widget.supervisor.areaDesignada ?? '');
  late final Map<String, (String, String)> _opcionesTurno;
  late String _turno;
  late String? _grupoId = widget.supervisor.grupoId;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // el backend envía "07:00:00"; los turnos usan "07:00"
    final actual = (widget.supervisor.horarioEntrada.substring(0, 5), widget.supervisor.horarioSalida.substring(0, 5));
    final coincidente = turnos.entries.where((t) => t.value == actual).map((t) => t.key).firstOrNull;
    // si el horario no es uno de los tres turnos (por ejemplo, uno antiguo), se ofrece para no perderlo
    _opcionesTurno = {
      ...turnos,
      if (coincidente == null) 'Horario actual (${actual.$1} - ${actual.$2})': actual,
    };
    _turno = coincidente ?? 'Horario actual (${actual.$1} - ${actual.$2})';
  }

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  Grupo? get _grupoElegido => widget.grupos.where((g) => g.id == _grupoId).firstOrNull;

  /// Aviso del intercambio cuando el grupo elegido ya tiene otro supervisor
  String? get _avisoIntercambio {
    final grupo = _grupoElegido;
    if (grupo == null || grupo.id == widget.supervisor.grupoId) return null;
    if (grupo.supervisorId == null) return null;
    final actual = widget.supervisor.grupoNombre;
    return actual == null
        ? '${grupo.supervisorNombre} quedará sin grupo.'
        : '${grupo.supervisorNombre} pasará al grupo "$actual".';
  }

  Future<void> _guardar() async {
    final (entrada, salida) = _opcionesTurno[_turno]!;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(supervisoresViewModelProvider.notifier).editar(
            supervisorId: widget.supervisor.id,
            horarioEntrada: entrada,
            horarioSalida: salida,
            areaDesignada: _area.text.trim().isEmpty ? null : _area.text.trim(),
            // solo se envía si cambió, para no repetir el intercambio
            grupoId: _grupoId == widget.supervisor.grupoId ? null : _grupoId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aviso = _avisoIntercambio;
    return AlertDialog(
      scrollable: true,
      title: Text('Editar ${widget.supervisor.nombreCompleto}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('editar_supervisor_turno'),
            initialValue: _turno,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Turno'),
            items: [for (final t in _opcionesTurno.keys) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: _guardando ? null : (t) => setState(() => _turno = t ?? _turno),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('editar_supervisor_area'),
            controller: _area,
            enabled: !_guardando,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Área designada', hintText: 'Ej. Embotellado'),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            key: const Key('editar_supervisor_grupo'),
            initialValue: _grupoId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Grupo'),
            items: [
              for (final g in widget.grupos)
                DropdownMenuItem(
                  value: g.id,
                  child: Text(
                    g.supervisorId == null || g.supervisorId == widget.supervisor.id
                        ? g.nombreDeGrupo
                        : '${g.nombreDeGrupo} · ${g.supervisorNombre}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _guardando ? null : (id) => setState(() => _grupoId = id),
          ),
          if (aviso != null) ...[
            const SizedBox(height: 8),
            Text('Los grupos se intercambian: $aviso', style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          const Text(
            'El grupo trabaja en el mismo turno que su supervisor. El nombre y los apellidos los cambia la propia persona en Mi Perfil.',
            style: TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 11),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
