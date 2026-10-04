import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/tecnicos_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';


enum _Profesion { electrico, mecanico, electromecanico }

extension on _Profesion {
  String get etiqueta => switch (this) {
        _Profesion.electrico => 'Eléctrico',
        _Profesion.mecanico => 'Mecánico',
        _Profesion.electromecanico => 'Electromecánico',
      };

  IconData get icono => switch (this) {
        _Profesion.electrico => Icons.bolt,
        _Profesion.mecanico => Icons.build,
        _Profesion.electromecanico => Icons.precision_manufacturing,
      };
}

class PantallaRegistrarTecnico extends ConsumerStatefulWidget {
  const PantallaRegistrarTecnico({super.key});

  @override
  ConsumerState<PantallaRegistrarTecnico> createState() =>
      _PantallaRegistrarTecnicoState();
}

class _PantallaRegistrarTecnicoState
    extends ConsumerState<PantallaRegistrarTecnico> {
  final _controladorNombre = TextEditingController();
  final _controladorApellidoPaterno = TextEditingController();
  final _controladorApellidoMaterno = TextEditingController();
  final _controladorUsuario = TextEditingController();
  _Profesion _profesionSeleccionada = _Profesion.electrico;
  bool _guardando = false;

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorApellidoPaterno.dispose();
    _controladorApellidoMaterno.dispose();
    _controladorUsuario.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _controladorNombre.text.trim();
    final apellidoPaterno = _controladorApellidoPaterno.text.trim();
    final nombreUsuario = _controladorUsuario.text.trim();
    if (nombre.isEmpty || apellidoPaterno.isEmpty || nombreUsuario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await ref.read(tecnicosViewModelProvider.notifier).crear(
            nombre: nombre,
            apellidoPaterno: apellidoPaterno,
            apellidoMaterno: _controladorApellidoMaterno.text.trim().isEmpty
                ? null
                : _controladorApellidoMaterno.text.trim(),
            nombreUsuario: nombreUsuario,
            profesion: _profesionSeleccionada.name,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(21, 8, 21, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AvatarConBadge(),
                    const SizedBox(height: 20),
                    _EtiquetaCampo(texto: 'Nombre', obligatorio: true),
                    const SizedBox(height: 6),
                    _CampoTexto(
                      controlador: _controladorNombre,
                      textoIndicativo: 'Ej. Carlos',
                    ),
                    const SizedBox(height: 16),
                    _EtiquetaCampo(texto: 'Apellido Paterno', obligatorio: true),
                    const SizedBox(height: 6),
                    _CampoTexto(
                      controlador: _controladorApellidoPaterno,
                      textoIndicativo: 'Ej. Mendoza',
                    ),
                    const SizedBox(height: 16),
                    _EtiquetaCampo(texto: 'Apellido Materno', obligatorio: false),
                    const SizedBox(height: 6),
                    _CampoTexto(
                      controlador: _controladorApellidoMaterno,
                      textoIndicativo: 'Ej. Salazar',
                    ),
                    const SizedBox(height: 16),
                    _EtiquetaCampo(texto: 'Nombre de Usuario', obligatorio: true),
                    const SizedBox(height: 6),
                    _CampoTexto(
                      controlador: _controladorUsuario,
                      textoIndicativo: 'cmendoza_tec',
                      prefijo: '@',
                    ),
                    const SizedBox(height: 16),
                    const _CampoGrupoAutomatico(),
                    const SizedBox(height: 16),
                    _SelectorProfesion(
                      seleccionada: _profesionSeleccionada,
                      onCambiar: (p) => setState(() => _profesionSeleccionada = p),
                    ),
                    const SizedBox(height: 16),
                    const _AvisoCredenciales(),
                    const SizedBox(height: 20),
                    _BotonGuardar(
                      onPressed: _guardando ? null : _guardar,
                      cargando: _guardando,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text(
                          'Cancelar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColoresApp.textoPlaceholder,
                            fontWeight: FontWeight.w700,
                          ),
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
            'Registrar Técnico',
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

class _AvatarConBadge extends StatelessWidget {
  const _AvatarConBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: ColoresApp.badgeFondo,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: ColoresApp.badgeBorde),
          ),
          child: const Text(
            'Formulario de Registro',
            style: TextStyle(
              color: ColoresApp.principal,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const CircleAvatar(
              radius: 55.5,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_outline,
                  size: 60, color: ColoresApp.textoPlaceholder),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColoresApp.principal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D2563EB),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EtiquetaCampo extends StatelessWidget {
  const _EtiquetaCampo({required this.texto, required this.obligatorio});
  final String texto;
  final bool obligatorio;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: ColoresApp.textoLabel,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(text: texto),
              if (obligatorio)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: ColoresApp.principal),
                ),
            ],
          ),
        ),
        if (obligatorio)
          const Text(
            'OBLIGATORIO',
            style: TextStyle(
              color: ColoresApp.textoPlaceholder,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: const Text(
              'OPCIONAL',
              style: TextStyle(
                color: ColoresApp.textoPlaceholder,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({
    required this.controlador,
    required this.textoIndicativo,
    this.prefijo,
  });
  final TextEditingController controlador;
  final String textoIndicativo;
  final String? prefijo;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14),
      decoration: InputDecoration(
        hintText: textoIndicativo,
        hintStyle: const TextStyle(color: ColoresApp.textoPlaceholder),
        prefixText: prefijo,
        prefixStyle: const TextStyle(
          color: ColoresApp.textoPlaceholder,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: ColoresApp.campoFondo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColoresApp.campoBorde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColoresApp.campoBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColoresApp.principal, width: 1.5),
        ),
      ),
    );
  }
}

class _CampoGrupoAutomatico extends StatelessWidget {
  const _CampoGrupoAutomatico();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            _EtiquetaCampo(texto: 'Grupo', obligatorio: false),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
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
              const Text(
                'Grupo 1 - Suministros',
                style: TextStyle(
                  color: ColoresApp.textoLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Text(
                'Mismo grupo del creador',
                style: TextStyle(
                  color: ColoresApp.textoPlaceholder,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectorProfesion extends StatelessWidget {
  const _SelectorProfesion({required this.seleccionada, required this.onCambiar});
  final _Profesion seleccionada;
  final ValueChanged<_Profesion> onCambiar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EtiquetaCampo(texto: 'Profesión / Especialidad', obligatorio: true),
        const SizedBox(height: 8),
        Row(
          children: _Profesion.values
              .map((p) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _PildoraProfesion(
                        profesion: p,
                        seleccionada: p == seleccionada,
                        onTap: () => onCambiar(p),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _PildoraProfesion extends StatelessWidget {
  const _PildoraProfesion({
    required this.profesion,
    required this.seleccionada,
    required this.onTap,
  });
  final _Profesion profesion;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: seleccionada ? const Color(0xFFEFF6FF) : const Color(0x99F8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionada ? ColoresApp.principal : ColoresApp.campoBorde,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              profesion.icono,
              size: 16,
              color: seleccionada ? ColoresApp.principal : ColoresApp.textoSuave,
            ),
            const SizedBox(height: 4),
            Text(
              profesion.etiqueta,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: seleccionada ? ColoresApp.principal : ColoresApp.textoSuave,
                fontSize: 12,
                fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoCredenciales extends StatelessWidget {
  const _AvisoCredenciales();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xCCEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xB3BFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
            ),
            child: const Icon(Icons.shield_outlined,
                size: 16, color: ColoresApp.principal),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La contraseña inicial será ESPODI2026',
                  style: TextStyle(
                    color: ColoresApp.textoOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'El técnico deberá cambiarla en su primer inicio de sesión.',
                  style: TextStyle(
                    color: Color(0xCC131D8C),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonGuardar extends StatelessWidget {
  const _BotonGuardar({required this.onPressed, this.cargando = false});
  final VoidCallback? onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [ColoresApp.gradienteInicio, ColoresApp.gradienteFin],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x472563EB),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Guardar Técnico',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
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
