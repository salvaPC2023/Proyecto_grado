import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: reemplazar por el provider real de HU-01 (funcionalidades/acceso_roles)
// una vez creado, por ejemplo en presentacion/pantallas/autenticacion/controlador_autenticacion.dart
// import '../../../nucleo/di.dart';

class PantallaInicioSesion extends ConsumerStatefulWidget {
  const PantallaInicioSesion({super.key});

  @override
  ConsumerState<PantallaInicioSesion> createState() =>
      _PantallaInicioSesionState();
}

class _PantallaInicioSesionState extends ConsumerState<PantallaInicioSesion> {
  final _controladorUsuario = TextEditingController();
  final _controladorContrasena = TextEditingController();
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _controladorUsuario.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final usuario = _controladorUsuario.text.trim();
    final contrasena = _controladorContrasena.text;
    if (usuario.isEmpty || contrasena.isEmpty) return;
    // TODO: llamar al caso de uso real de login (HU-01) en vez de esta linea
    // await ref.read(controladorAutenticacionProvider.notifier).iniciarSesion(usuario, contrasena);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: reemplazar por el estado real del controlador de autenticacion
    final estadoCargando = false;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0E7FF), Colors.white],
            stops: [0.0, 0.55],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/portada.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF0E7FF), Color(0xFFE0D0FF)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.engineering,
                            size: 110,
                            color: Color(0x596338E8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          'Bienvenido de nuevo',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Gestiona tus tareas de mantenimiento con\neficiencia y precisión.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _EtiquetaCampo('Usuario'),
                      const SizedBox(height: 8),
                      _CampoEstilizado(
                        controlador: _controladorUsuario,
                        textoIndicativo: 'ej. tecnico01',
                        iconoPrefijo: Icons.person_outline,
                        accionTeclado: TextInputAction.next,
                        habilitado: !estadoCargando,
                      ),
                      const SizedBox(height: 20),
                      const _EtiquetaCampo('Contraseña'),
                      const SizedBox(height: 8),
                      _CampoEstilizado(
                        controlador: _controladorContrasena,
                        textoIndicativo: '••••••••',
                        iconoPrefijo: Icons.lock_outline,
                        ocultarTexto: _ocultarContrasena,
                        accionTeclado: TextInputAction.done,
                        habilitado: !estadoCargando,
                        alEnviar: (_) => _enviar(),
                        iconoSufijo: IconButton(
                          icon: Icon(
                            _ocultarContrasena
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _ocultarContrasena = !_ocultarContrasena),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: estadoCargando ? null : _enviar,
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: estadoCargando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1F),
          ),
    );
  }
}

class _CampoEstilizado extends StatelessWidget {
  const _CampoEstilizado({
    required this.controlador,
    required this.textoIndicativo,
    required this.iconoPrefijo,
    this.ocultarTexto = false,
    this.accionTeclado = TextInputAction.next,
    this.habilitado = true,
    this.alEnviar,
    this.iconoSufijo,
  });

  final TextEditingController controlador;
  final String textoIndicativo;
  final IconData iconoPrefijo;
  final bool ocultarTexto;
  final TextInputAction accionTeclado;
  final bool habilitado;
  final ValueChanged<String>? alEnviar;
  final Widget? iconoSufijo;

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controlador,
      decoration: InputDecoration(
        prefixIcon: Icon(iconoPrefijo, color: Colors.grey[500], size: 20),
        hintText: textoIndicativo,
        hintStyle: TextStyle(color: Colors.grey[400]),
        suffixIcon: iconoSufijo,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      obscureText: ocultarTexto,
      textInputAction: accionTeclado,
      enabled: habilitado,
      onSubmitted: alEnviar,
    );
  }
}
