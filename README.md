# Maintenance App — Gestión de Órdenes de Trabajo

Sistema de gestión de órdenes de trabajo para el área de Mantenimiento de ESPODI.
Gestiona las Órdenes de Trabajo (OT) con una vista separada para el supervisor y el técnico, notifica al personal técnico de sus tareas y estandariza las descripciones de trabajo con un modelo de lenguaje.

## Tecnologías

- **Backend:** Python 3.12, FastAPI, SQLAlchemy 2, Alembic y PostgreSQL 17. Arquitectura hexagonal organizada por módulos (vertical slicing).
- **App móvil:** Flutter con Riverpod y Dio. Clean Architecture con MVVM.

## Metodología

Este proyecto se gestiona con **Scrum** y **Kanban** (Scrumban).

## Estructura

El backend tiene un módulo por tema: `acceso_roles`, `ubicaciones_tecnicas` y `ordenes_trabajo`. Cada módulo se divide en `dominio`, `aplicacion` e `infraestructura`. Lo que comparten todos (conexión a la base, configuración y seguridad) está en `backend/src/compartido`.

La app móvil (`mobile/lib`) se organiza por capas: `dominio` (modelos y contratos de repositorio), `datos` (implementación de los contratos contra la API), `presentacion` (pantallas y ViewModels) y `nucleo` (cliente HTTP, sesión, inyección de dependencias y tema).

## Puesta en marcha en una computadora nueva

Requisitos: Git, Python 3.12, PostgreSQL 17, Flutter y Android Studio (para el Android SDK y el emulador).

### Base de datos

1. En pgAdmin, crear la base `mantenimiento_db`.
2. Crear sus tablas con el script de la base de datos.

### Backend

Desde la carpeta `backend`:

```terminal
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
alembic stamp head
```

Antes de `alembic stamp head` hay que crear en `backend` un archivo `.env` con estas dos variables:

```env
DATABASE_URL=postgresql://postgres:<contraseña>@localhost:5432/mantenimiento_db
JWT_SECRET_KEY=<una cadena larga y aleatoria>
```

`alembic stamp head` registra que la base ya está en la última versión, sin ejecutar migraciones.

Para empezar hace falta un administrador, que se crea directamente en la base; después, el administrador registra a los supervisores desde la app, y cada supervisor registra a sus técnicos. La contraseña se guarda cifrada; el valor para `password_hash` se obtiene con:

```terminal
python -c "from src.compartido.seguridad import hashear_password; print(hashear_password('LaContrasena'))"
```

Con ese valor, en pgAdmin:

```sql
INSERT INTO usuarios (id, nombre, apellido_paterno, nombre_usuario, password_hash, activo, debe_cambiar_password)
VALUES (gen_random_uuid(), 'Nombre', 'Apellido', 'admin', '<password_hash>', true, false);

INSERT INTO administradores (id, usuario_id)
SELECT gen_random_uuid(), id FROM usuarios WHERE nombre_usuario = 'admin';
```

### App móvil

Desde la carpeta `mobile`:

```terminal
flutter pub get
```

### Emulador Android

Se crea una sola vez desde Android Studio, en Device Manager. Representa un celular de gama media baja (pantalla de 360x800 dp):

1. New Hardware Profile: nombre `Gama media baja`, pantalla de 6.5", resolución 720x1600 y 3 GB de RAM.
2. Imagen del sistema: API 34 (Android 14), Google APIs x86_64.
3. Ajustes avanzados: 3 GB de RAM y 2 núcleos de CPU.
4. Con el emulador encendido, fijar la densidad en 320 para que Flutter vea 360x800:

```terminal
adb shell wm density 320
```

`adb` está en `%LOCALAPPDATA%\Android\Sdk\platform-tools`, que debe estar en el PATH.

## Ejecución diaria

Backend, desde `backend` con el entorno virtual activo:

```terminal
cd backend
.\.venv\Scripts\Activate.ps1
uvicorn src.main:app --reload
```

La app móvil se ejecuta en otra terminal, desde `mobile`. No hace falta el entorno virtual.

En el navegador:

```terminal
flutter run -d edge
```

En el emulador Android:

```terminal
flutter emulators --launch Gama_media_baja
flutter devices
adb reverse tcp:8000 tcp:8000
flutter run -d emulator-5554
```

- `flutter devices` sirve para confirmar que el emulador ya terminó de arrancar y ver su id (normalmente `emulator-5554`).
- `adb reverse` hace que `localhost:8000` dentro del emulador apunte al backend de la PC. Se repite cada vez que el emulador se reinicia.
- Si el emulador ya está abierto, `flutter emulators --launch` falla con `exited with code 1`. En ese caso se salta ese paso y se busca su ventana con Alt+Tab.
- Si el emulador se cuelga, se cierra con `adb -s emulator-5554 emu kill` y se vuelve a lanzar.

En un celular conectado por USB, con la depuración USB activada:

```terminal
flutter devices
adb reverse tcp:8000 tcp:8000
flutter run -d <id>
```

Mientras la app corre: `r` recarga los cambios, `R` reinicia la app y `q` la detiene.

## Pruebas

```terminal
cd backend
pytest
```

```terminal
cd mobile
flutter analyze
flutter test
```

### Coverage

Desde backend con el entorno virtual activo:

```terminal
cd backend
pytest --cov --cov-report=term-missing
```

La tabla sale en la terminal (la columna "Missing" indica las líneas sin probar).

Desde mobile:

```terminal
cd mobile
flutter test --coverage
```

El resultado queda en mobile/coverage/lcov.info. Para verlo línea por línea en VS Code se usa la extensión Coverage Gutters.
