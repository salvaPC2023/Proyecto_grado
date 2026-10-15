class ReglaPassword {
  const ReglaPassword(this.descripcion, this.seCumple);

  final String descripcion;

  final bool Function(String password) seCumple;
}

const _caracteresEspeciales = r'''!@#$%^&*()-_=+[]{}|;:'",.<>?/`~''';

// lista de reglas con funciones cortas
final reglasPassword = <ReglaPassword>[
  ReglaPassword('Entre 8 y 20 caracteres', (p) => p.length >= 8 && p.length <= 20),
  ReglaPassword('Una letra mayúscula', (p) => p != p.toLowerCase()),
  ReglaPassword('Una letra minúscula', (p) => p != p.toUpperCase()),
  ReglaPassword('Un número', (p) => p.contains(RegExp(r'[0-9]'))),
  ReglaPassword(
    'Un carácter especial',
    (p) => p.split('').any((c) => _caracteresEspeciales.contains(c)),
  ),
];

// pasa solo si se cumplen todas las reglas
bool passwordEsValida(String password) =>
    reglasPassword.every((regla) => regla.seCumple(password));