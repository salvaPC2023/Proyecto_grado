import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores.dart';
import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/perfil_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';

class PantallaMiPerfil extends ConsumerStatefulWidget {
  const PantallaMiPerfil({super.key});

  @override
  ConsumerState<PantallaMiPerfil> createState() => _PantallaMiPerfilState();
}

class _PantallaMiPerfilState extends ConsumerState<PantallaMiPerfil> {
  final _controladorNombre = TextEditingController();
  final _controladorApellidoPaterno = TextEditingController();
  final _controladorApellidoMaterno = TextEditingController();
  final _controladorPasswordActual = TextEditingController();
  final _controladorPasswordNueva = TextEditingController();
  bool _ocultarPasswordActual = true;
  bool _ocultarPasswordNueva = true;
  bool _guardando = false;
  bool _controladoresInicializados = false;

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorApellidoPaterno.dispose();
    _controladorApellidoMaterno.dispose();
    _controladorPasswordActual.dispose();
    _controladorPasswordNueva.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    final passwordActual = _controladorPasswordActual.text;
    final passwordNueva = _controladorPasswordNueva.text;
    if (passwordActual.isEmpty != passwordNueva.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa las dos contraseñas para cambiarla, o ninguna'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await ref.read(perfilViewModelProvider.notifier).guardarCambios(
            nombre: _controladorNombre.text.trim(),
            apellidoPaterno: _controladorApellidoPaterno.text.trim(),
            apellidoMaterno: _controladorApellidoMaterno.text.trim().isEmpty
                ? null
                : _controladorApellidoMaterno.text.trim(),
          );

      if (passwordActual.isNotEmpty) {
        await ref.read(perfilViewModelProvider.notifier).cambiarPassword(
              passwordActual: passwordActual,
              passwordNueva: passwordNueva,
            );
        _controladorPasswordActual.clear();
        _controladorPasswordNueva.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e))),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoPerfil = ref.watch(perfilViewModelProvider);
    final esSupervisor = ref.watch(sesionProvider)?.esSupervisor ?? false;

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            _Encabezado(onVolver: () => Navigator.of(context).maybePop()),
            Expanded(
              child: estadoPerfil.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      mensajeDeError(error),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ColoresApp.textoOscuro),
                    ),
                  ),
                ),
                data: (perfil) {
                  if (!_controladoresInicializados) {
                    _controladorNombre.text = perfil.nombre;
                    _controladorApellidoPaterno.text = perfil.apellidoPaterno;
                    _controladorApellidoMaterno.text = perfil.apellidoMaterno ?? '';
                    _controladoresInicializados = true;
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(21, 8, 21, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _AvatarConBadge(),
                        const SizedBox(height: 20),
                        const _EtiquetaCampo('Nombre'),
                        const SizedBox(height: 6),
                        _CampoTexto(controlador: _controladorNombre),
                        const SizedBox(height: 16),
                        const _EtiquetaCampo('Apellido Paterno'),
                        const SizedBox(height: 6),
                        _CampoTexto(controlador: _controladorApellidoPaterno),
                        const SizedBox(height: 16),
                        const _EtiquetaCampo('Apellido Materno'),
                        const SizedBox(height: 6),
                        _CampoTexto(controlador: _controladorApellidoMaterno),
                        const SizedBox(height: 16),
                        _CampoBloqueado(
                          etiqueta: 'Nombre de Usuario',
                          valor: '@${perfil.nombreUsuario}',
                          icono: Icons.lock_outline,
                        ),
                        const SizedBox(height: 16),
                        if (!esSupervisor) ...[
                          _CampoGrupo(valor: perfil.grupoNombre ?? '—'),
                          const SizedBox(height: 16),
                          _CampoProfesion(valor: perfil.profesion ?? '—'),
                          const SizedBox(height: 16),
                        ] else ...[
                          _CampoBloqueado(
                            etiqueta: 'Grupo a cargo',
                            valor: perfil.grupoNombre ?? '—',
                            icono: Icons.groups_outlined,
                          ),
                          const SizedBox(height: 16),
                          _CampoBloqueado(
                            etiqueta: 'Horario',
                            valor: perfil.horarioEntrada != null &&
                                    perfil.horarioSalida != null
                                ? '${perfil.horarioEntrada!.substring(0, 5)} - ${perfil.horarioSalida!.substring(0, 5)}'
                                : '—',
                            icono: Icons.schedule_outlined,
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 4),
                        _SeccionCambioPassword(
                          controladorActual: _controladorPasswordActual,
                          controladorNueva: _controladorPasswordNueva,
                          ocultarActual: _ocultarPasswordActual,
                          ocultarNueva: _ocultarPasswordNueva,
                          alAlternarActual: () => setState(() =>
                              _ocultarPasswordActual = !_ocultarPasswordActual),
                          alAlternarNueva: () => setState(
                              () => _ocultarPasswordNueva = !_ocultarPasswordNueva),
                        ),
                        const SizedBox(height: 20),
                        _BotonGuardar(
                          onPressed: _guardando ? null : _guardarCambios,
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 90),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.inicio),
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
            'Mi Perfil',
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

class _AvatarConBadge extends ConsumerWidget {
  const _AvatarConBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esSupervisor = ref.watch(sesionProvider)?.esSupervisor ?? false;
    final imagenAvatar = esSupervisor
        ? 'assets/images/icono_supervisor.png'
        : 'assets/images/icono_tecnico.png';
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
        CircleAvatar(
          radius: 55.5,
          backgroundColor: Colors.white,
          backgroundImage: AssetImage(imagenAvatar),
        ),
      ],
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

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({required this.controlador});
  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: ColoresApp.campoFondo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

class _CampoBloqueado extends StatelessWidget {
  const _CampoBloqueado({
    required this.etiqueta,
    required this.valor,
    required this.icono,
  });
  final String etiqueta;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _EtiquetaCampo(etiqueta),
            const SizedBox(width: 6),
            Icon(icono, size: 14, color: ColoresApp.textoPlaceholder),
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
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 2),
                  ],
                ),
                child: const Icon(Icons.bolt, size: 16, color: ColoresApp.principal),
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

class _SeccionCambioPassword extends StatelessWidget {
  const _SeccionCambioPassword({
    required this.controladorActual,
    required this.controladorNueva,
    required this.ocultarActual,
    required this.ocultarNueva,
    required this.alAlternarActual,
    required this.alAlternarNueva,
  });

  final TextEditingController controladorActual;
  final TextEditingController controladorNueva;
  final bool ocultarActual;
  final bool ocultarNueva;
  final VoidCallback alAlternarActual;
  final VoidCallback alAlternarNueva;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_reset, size: 16, color: ColoresApp.textoOscuro),
              SizedBox(width: 6),
              Text(
                'Cambio de Contraseña',
                style: TextStyle(
                  color: ColoresApp.textoOscuro,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CampoPassword(
            etiqueta: 'Contraseña Actual',
            controlador: controladorActual,
            ocultar: ocultarActual,
            alAlternar: alAlternarActual,
            textoIndicativo: '••••••••',
          ),
          const SizedBox(height: 10),
          _CampoPassword(
            etiqueta: 'Nueva Contraseña',
            controlador: controladorNueva,
            ocultar: ocultarNueva,
            alAlternar: alAlternarNueva,
            textoIndicativo: 'Ingresa nueva contraseña',
          ),
        ],
      ),
    );
  }
}

class _CampoPassword extends StatelessWidget {
  const _CampoPassword({
    required this.etiqueta,
    required this.controlador,
    required this.ocultar,
    required this.alAlternar,
    this.textoIndicativo,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final bool ocultar;
  final VoidCallback alAlternar;
  final String? textoIndicativo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: ColoresApp.textoSuave,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controlador,
          obscureText: ocultar,
          style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14),
          decoration: InputDecoration(
            hintText: textoIndicativo,
            filled: true,
            fillColor: ColoresApp.campoFondo,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            suffixIcon: IconButton(
              icon: Icon(
                ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 16,
                color: ColoresApp.textoPlaceholder,
              ),
              onPressed: alAlternar,
            ),
          ),
        ),
      ],
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
                        'Guardar Cambios',
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
