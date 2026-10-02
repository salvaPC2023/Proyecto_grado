import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/tecnicos_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';

// TODO: "grupo" sigue recibido por parametro con un valor de ejemplo — no
// hay forma de saber el NOMBRE del grupo todavia (GET /tecnicos solo manda
// su id). El resto (nombre, usuario, profesion, activo) ya es real.

class PantallaVerPerfilTecnico extends ConsumerStatefulWidget {
  const PantallaVerPerfilTecnico({
    super.key,
    required this.id,
    required this.nombreCompleto,
    required this.nombreUsuario,
    required this.grupo,
    required this.profesion,
    required this.activo,
  });

  final String id;
  final String nombreCompleto;
  final String nombreUsuario;
  final String grupo;
  final String profesion;
  final bool activo;

  @override
  ConsumerState<PantallaVerPerfilTecnico> createState() =>
      _PantallaVerPerfilTecnicoState();
}

class _PantallaVerPerfilTecnicoState
    extends ConsumerState<PantallaVerPerfilTecnico> {
  late bool _activo = widget.activo;
  bool _cambiandoEstado = false;

  Future<void> _alternarEstado() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_activo ? 'Deshabilitar cuenta' : 'Habilitar cuenta'),
        content: Text(
          _activo
              ? '¿Está seguro de que desea deshabilitar la cuenta de ${widget.nombreCompleto}? El técnico no podrá iniciar sesión.'
              : '¿Está seguro de que desea habilitar la cuenta de ${widget.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _activo ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_activo ? 'Deshabilitar' : 'Habilitar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _cambiandoEstado = true);
    try {
      await ref
          .read(tecnicosViewModelProvider.notifier)
          .cambiarEstado(widget.id, !_activo);
      if (!mounted) return;
      setState(() => _activo = !_activo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_activo ? 'Cuenta habilitada' : 'Cuenta deshabilitada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _cambiandoEstado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partes = widget.nombreCompleto.trim().split(' ');
    final nombre = partes.isNotEmpty ? partes.first : '';
    final apellidoPaterno = partes.length > 1 ? partes[1] : '';
    final apellidoMaterno = partes.length > 2 ? partes.sublist(2).join(' ') : '';

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            _Encabezado(onVolver: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(21, 8, 21, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Avatar(),
                    const SizedBox(height: 20),
                    _CampoSoloLectura(etiqueta: 'Nombre', valor: nombre),
                    const SizedBox(height: 16),
                    _CampoSoloLectura(
                        etiqueta: 'Apellido Paterno', valor: apellidoPaterno),
                    if (apellidoMaterno.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _CampoSoloLectura(
                          etiqueta: 'Apellido Materno', valor: apellidoMaterno),
                    ],
                    const SizedBox(height: 16),
                    _CampoBloqueado(
                      etiqueta: 'Nombre de Usuario',
                      valor: '@${widget.nombreUsuario}',
                    ),
                    const SizedBox(height: 16),
                    _CampoGrupo(valor: widget.grupo),
                    const SizedBox(height: 16),
                    _CampoProfesion(valor: widget.profesion),
                    const SizedBox(height: 16),
                    _EstadoCuenta(activo: _activo),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cambiandoEstado ? null : _alternarEstado,
                        icon: _cambiandoEstado
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_activo
                                ? Icons.block_outlined
                                : Icons.check_circle_outline),
                        label: Text(_activo ? 'Deshabilitar cuenta' : 'Habilitar cuenta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              _activo ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          side: BorderSide(
                            color: _activo ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 90),
                  ],
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
  const _Encabezado({required this.onVolver});
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: ColoresApp.fondo.withValues(alpha: 0.9),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BotonCircular(icono: Icons.arrow_back, onPressed: onVolver),
          ),
          const Text(
            'Perfil del Técnico',
            style: TextStyle(
              color: ColoresApp.textoOscuro,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircleAvatar(
        radius: 55.5,
        backgroundColor: Colors.white,
        backgroundImage: AssetImage('assets/images/icono_tecnico.png'),
      ),
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
        color: ColoresApp.textoLabel,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CampoSoloLectura extends StatelessWidget {
  const _CampoSoloLectura({required this.etiqueta, required this.valor});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EtiquetaCampo(etiqueta),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ColoresApp.campoFondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColoresApp.campoBorde),
          ),
          child: Text(
            valor,
            style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CampoBloqueado extends StatelessWidget {
  const _CampoBloqueado({required this.etiqueta, required this.valor});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _EtiquetaCampo(etiqueta),
            const SizedBox(width: 6),
            const Icon(Icons.lock_outline, size: 14, color: ColoresApp.textoPlaceholder),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ColoresApp.campoBloqueadoFondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColoresApp.campoBorde),
          ),
          child: Text(
            valor,
            style: const TextStyle(
              color: ColoresApp.textoLabel,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CampoGrupo extends StatelessWidget {
  const _CampoGrupo({required this.valor});
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            _EtiquetaCampo('Grupo'),
            SizedBox(width: 6),
            Icon(Icons.lock_outline, size: 14, color: ColoresApp.textoPlaceholder),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ColoresApp.campoBloqueadoFondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColoresApp.campoBorde),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ColoresApp.principal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valor,
                style: const TextStyle(
                  color: ColoresApp.textoLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CampoProfesion extends StatelessWidget {
  const _CampoProfesion({required this.valor});
  final String valor;

  IconData get _icono => switch (valor.toLowerCase()) {
        'electrico' => Icons.bolt,
        'mecanico' => Icons.build,
        'electromecanico' => Icons.precision_manufacturing,
        _ => Icons.engineering,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            _EtiquetaCampo('Profesión / Especialidad'),
            SizedBox(width: 6),
            Icon(Icons.lock_outline, size: 14, color: ColoresApp.textoPlaceholder),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ColoresApp.chipProfesionFondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColoresApp.chipProfesionBorde),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                ),
                child: Icon(_icono, size: 16, color: ColoresApp.principal),
              ),
              const SizedBox(width: 10),
              Text(
                valor,
                style: const TextStyle(
                  color: ColoresApp.principal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EstadoCuenta extends StatelessWidget {
  const _EstadoCuenta({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'ESTADO',
            style: TextStyle(
              color: ColoresApp.textoPlaceholder,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: activo ? const Color(0xFF10B981) : ColoresApp.textoPlaceholder,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            activo ? 'Activo' : 'Inactivo',
            style: const TextStyle(
              color: ColoresApp.textoOscuro,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
