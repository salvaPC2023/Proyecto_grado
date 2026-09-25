# Maintenance App — Gestión de Órdenes de Trabajo

Sistema de gestión de mantenimiento para el área de Mantenimiento de ESPODI.
Estandariza el registro de Órdenes de Trabajo (OT) preventivas (PM01), notifica al
personal técnico y estandariza las descripciones de trabajo con un modelo de lenguaje.

- **Backend:** Python 3.12.5 + FastAPI · PostgreSQL · arquitectura hexagonal + vertical slicing
- **App móvil:** Flutter (Dart) · MVVM + Riverpod · Drift (SQLite) para operación sin conexión
- **LLM:** API de OpenAI (`gpt-4o-mini`) vía adaptador de salida, solo para estandarización de descripciones

## Metodología

Este proyecto se gestiona con **Scrum**.
Ver [`docs/scrum/`](docs/scrum/)

## Estructura del repositorio

```
maintenance-app/
├── backend/          # API FastAPI — hexagonal + vertical slicing
│   └── src/
│       ├── modulos/                  # una rebanada por tema del backlog (E1–E6)
│       │   └── <modulo>/
│       │       ├── dominio/          # modelos + puertos (lógica pura)
│       │       ├── aplicacion/       # casos de uso
│       │       └── infraestructura/  # adaptadores: PostgreSQL, LLM, endpoints
│       └── compartido/               # BD, configuración, seguridad, tipos comunes
├── mobile/           # app Flutter — Clean Architecture + MVVM, offline-first
│   └── lib/
│       ├── dominio/            # modelos y contratos de repositorio
│       ├── datos/              # implementaciones remota (API) y local (Drift)
│       ├── presentacion/       # pantallas, widgets, ViewModels (Riverpod)
│       └── nucleo/             # router, inyección de dependencias, constantes
└── docs/
    ├── scrum/        # artefactos y evidencia de la metodología
    ├── arquitectura/ # QAS y justificación de la arquitectura
    ├── conciliacion.md
    └── Base de Datos/Query.txt   # esquema de la BD (fuente de verdad del modelo)
```

## Puesta en marcha en una computadora nueva

Backend y app móvil requieren PostgreSQL corriendo localmente con la base `mantenimiento_db`
(esquema en [`docs/Base de Datos/Query.txt`](docs/Base%20de%20Datos/Query.txt)) antes de arrancar.

### Backend

```powershell
cd backend
py -m venv .venv # SOLO EN PC NUEVA (Crea un venv nuevo)
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt # SOLO EN PC NUEVA
copy .env.example .env   # completar DATABASE_URL y JWT_SECRET_KEY con valores reales 
uvicorn src.main:app --reload
```

Backend disponible en `http://localhost:8000/docs` (Swagger).

### Frontend

```powershell
cd mobile
flutter pub get
flutter run
```

> Estado: en construcción (Sprint 1 — base técnica, autenticación y usuarios). Ver
> [`docs/scrum/sprint-plan.md`](docs/scrum/sprint-plan.md) para el alcance de cada sprint.

