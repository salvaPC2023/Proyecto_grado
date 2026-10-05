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

Requisitos: Git, Python 3.12, PostgreSQL 17 y Flutter.

### Base de datos

1. En pgAdmin, crear la base `mantenimiento_db`.
2. Ejecutar sobre ella el contenido de `Query.txt`.

### Backend

Desde la carpeta `backend`:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
alembic stamp head
```

En `.env` hay que completar `DATABASE_URL` (con la contraseña de PostgreSQL) y `JWT_SECRET_KEY` (una cadena larga y aleatoria).

`alembic stamp head` registra que la base creada con `Query.txt` ya está en la última versión, sin ejecutar migraciones.

Para iniciar sesión hace falta al menos un supervisor con su grupo, que se crea directamente en la base. La contraseña se guarda cifrada; el valor para `password_hash` se obtiene con:

```powershell
python -c "from src.compartido.seguridad import hashear_password; print(hashear_password('LaContrasena'))"
```

### App móvil

Desde la carpeta `mobile`:

```powershell
flutter pub get
```

## Ejecución diaria

Backend, desde `backend` con el entorno virtual activo:

```powershell
cd backend
uvicorn src.main:app --reload
```

App móvil, desde `navegador`:

```powershell
flutter run -d edge
```

App móvil, desde `simulador android SDK`:

```powershell
flutter emulators --launch <nombre>
flutter run -d emulator-5554
```

App móvil, desde `celular conectado a la pc`:

```powershell
flutter devices
flutter run -d <id>
```

## Pruebas

```powershell
cd backend
pytest
```

```powershell
cd mobile
flutter analyze
flutter test
```