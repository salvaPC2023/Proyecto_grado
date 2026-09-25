import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: reemplazar por el provider real de HU-02/HU-03 (funcionalidades/acceso_roles)
// import '../../../nucleo/di.dart';
// TODO: reemplazar por el modelo de dominio real (mobile/lib/dominio/modelos/tecnico.dart)
// con los campos de Query.txt: id, nombre, apellidoPaterno, apellidoMaterno, nombreUsuario,
// activo (bool, no un enum de estado), grupoId, profesion.

class PantallaDetalleTecnico extends ConsumerStatefulWidget {
  const PantallaDetalleTecnico({super.key, required this.idTecnico});
  final String idTecnico;

  @override
  ConsumerState<PantallaDetalleTecnico> createState() =>
      _PantallaDetalleTecnicoState();
}

class _PantallaDetalleTecnicoState
    extends ConsumerState<PantallaDetalleTecnico> {
  final _controladorNombre = TextEditingController();
  String? _grupoSeleccionadoId;
  bool _inicializado = false;

  @override
  void dispose() {
    _controladorNombre.dispose();
    super.dispose();
  }

  void _inicializarCampos() {
    if (_inicializado) return;
    // TODO: llenar _controladorNombre.text y _grupoSeleccionadoId
    // a partir del Tecnico real obtenido del provider
    _inicializado = true;
  }

  Future<void> _guardar() async {
    try {
      // TODO: llamar al caso de uso real de editar tecnico
      // await ref.read(controladorTecnicosProvider.notifier).editarTecnico(
      //   widget.idTecnico, nombre: _controladorNombre.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // activo=true -> deshabilitar; activo=false -> habilitar (HU-03)
  Future<void> _alternarEstado(bool activo) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(activo ? 'Deshabilitar cuenta' : 'Habilitar cuenta'),
        content: Text(
          activo
              ? '¿Está seguro de que desea deshabilitar esta cuenta? El técnico no podrá iniciar sesión.'
              : '¿Está seguro de que desea habilitar esta cuenta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: activo ? Colors.orange : Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: Text(activo ? 'Deshabilitar' : 'Habilitar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      // TODO: llamar al caso de uso real de cambiar estado de cuenta (HU-03)
      // await ref.read(controladorTecnicosProvider.notifier)
      //     .cambiarEstadoCuenta(widget.idTecnico, activo: !activo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(activo ? 'Cuenta deshabilitada' : 'Cuenta habilitada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: reemplazar por el Tecnico real leido del provider (ver arriba)
    const nombreTecnico = '—';
    const nombreUsuarioTecnico = '—';
    const activo = true;

    _inicializarCampos();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Editar técnico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.person_outline, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Datos del técnico',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _EtiquetaCampo('Nombre'),
                  const SizedBox(height: 6),
                  _CampoEdicion(controlador: _controladorNombre),
                  const SizedBox(height: 16),
                  const _EtiquetaCampo('Nombre de usuario'),
                  const SizedBox(height: 6),
                  _CampoSoloLectura(valor: nombreUsuarioTecnico),
                  const SizedBox(height: 4),
                  Text(
                    'El nombre de usuario no puede modificarse',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  const _EtiquetaCampo('Grupo'),
                  const SizedBox(height: 6),
                  // TODO: reemplazar por un DropdownButtonFormField con los grupos reales
                  DropdownButtonFormField<String>(
                    value: _grupoSeleccionadoId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [],
                    onChanged: (v) =>
                        setState(() => _grupoSeleccionadoId = v),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _guardar,
                      child: const Text('Guardar cambios'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                            color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _alternarEstado(activo),
                icon: Icon(
                    activo ? Icons.block_outlined : Icons.check_circle_outline),
                label: Text(activo ? 'Deshabilitar cuenta' : 'Habilitar cuenta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: activo ? Colors.orange : Colors.green,
                  side: BorderSide(color: activo ? Colors.orange : Colors.green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EtiquetaCampo extends StatelessWidget {
  const _EtiquetaCampo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
          color: Color(0xFF1D1D1F)),
    );
  }
}

class _CampoEdicion extends StatelessWidget {
  const _CampoEdicion({required this.controlador});
  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controlador,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primario, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _CampoSoloLectura extends StatelessWidget {
  const _CampoSoloLectura({required this.valor});
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                  color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ),
          Icon(Icons.lock_outline, size: 18, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
