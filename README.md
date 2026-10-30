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

En pgAdmin, crear la base vacía `mantenimiento_db`. Las tablas las crea Alembic en el paso siguiente.

Para ver el esquema completo en SQL legible, se genera desde la migración con `alembic upgrade head --sql` (no se guarda en el repositorio).

### Backend

Desde la carpeta `backend`:

```terminal
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
alembic upgrade head
```

Antes de `alembic upgrade head` hay que crear en `backend` un archivo `.env` con estas variables:

```env
DATABASE_URL=postgresql://postgres:<contraseña>@localhost:5432/mantenimiento_db
JWT_SECRET_KEY=<una cadena larga y aleatoria>
ADMIN_USUARIO_INICIAL=admin
ADMIN_PASSWORD_INICIAL=<contraseña inicial del administrador>
```

`alembic upgrade head` crea todas las tablas en la base vacía.

Al arrancar, si no hay ningún administrador, el backend crea uno con `ADMIN_USUARIO_INICIAL` y `ADMIN_PASSWORD_INICIAL`; en su primer ingreso debe cambiar usuario y contraseña. Después, el administrador registra a los supervisores (o los importa desde Excel) y cada supervisor registra a sus técnicos.

Para volver a empezar con la base vacía:

```terminal
alembic downgrade base
alembic upgrade head
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
.\.venv\Scripts\Activate.ps1
pytest --cov --cov-report=term-missing
```

La tabla sale en la terminal (la columna "Missing" indica las líneas sin probar).

Desde mobile:

```terminal
cd mobile
flutter test --coverage
```

El resultado queda en mobile/coverage/lcov.info. Para verlo línea por línea en VS Code se usa la extensión Coverage Gutters.

### APK

flutter build apk --release --dart-define=API_URL=https://ruby-frosty-cozily.ngrok-free.dev/api/v1