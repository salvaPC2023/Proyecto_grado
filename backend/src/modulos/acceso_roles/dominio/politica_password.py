CARACTERES_ESPECIALES = "!@#$%^&*()-_=+[]{}|;:'\",.<>?/`~"

def validar_password(password: str) -> list[str]:
    errores = []
    if not 8 <= len(password) <= 20:
        errores.append("La contraseña debe tener al menos 8 caracteres y no más de 20.")
    if not any(char.isdigit() for char in password):
        errores.append("La contraseña debe contener al menos un número.")
    if not any(char.isupper() for char in password):
        errores.append("La contraseña debe contener al menos una letra mayúscula.")
    if not any(char.islower() for char in password):
        errores.append("La contraseña debe contener al menos una letra minúscula.")
    if not any(char in CARACTERES_ESPECIALES for char in password):
        errores.append("La contraseña debe contener al menos un carácter especial.")
    return errores