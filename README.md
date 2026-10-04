# Maintenance App — Gestión de Órdenes de Trabajo

Sistema de gestión de ordenes de trabajo para el área de Mantenimiento de ESPODI.
Gestiona las Órdenes de Trabajo (OT) con una vista separa para el supervisor y técnico, notifica al personal técnico de sus tareas y estandariza las descripciones de trabajo con un modelo de lenguaje.

- **Backend:** Python 3.12.5 + FastAPI / PostgreSQL / arquitectura hexagonal + vertical slicing
- **App móvil:** Flutter (Dart) / MVVM + Riverpod / Drift (SQLite) para operación sin conexión
- **LLM:** API de OpenAI vía adaptador de salida, solo para estandarización de descripciones

## Metodología

Este proyecto se gestiona con **Scrum** y **Kanban**.
**Scrumban**

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
    └── lib/
        ├── dominio/            # modelos y contratos de repositorio
        ├── datos/              # implementaciones remota (API) y local (Drift)
        ├── presentacion/       # pantallas, widgets, ViewModels (Riverpod)
        └── nucleo/             # router, inyección de dependencias, constantes
```

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
