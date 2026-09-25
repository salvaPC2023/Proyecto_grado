> ⚠️ **Acta desactualizada.** Se redactó para el plan 8–14 sep con nombres del código de
> referencia (`notified`, `turno vigente`, rutas `domain/…`). Regenerar tras fijar la fecha
> de entrega (conciliacion.md D-06) y con la estructura `funcionalidades/<x>/…` y los
> estados `asignada / en progreso / cerrada`.

# Sprint 1 — Planning
Fecha: 2026-09-08
Duración del sprint: 2 días (2026-09-08 → 2026-09-09)

## Objetivo del Sprint
Un Supervisor puede crear una OT vía API y un Técnico puede listarla, ver su detalle y
registrar el cierre del paso PM01. Autenticación y roles operativos.

## Historias comprometidas
| HU | Título | Pts | Criterio de "hecho" para este sprint |
|----|--------|----:|--------------------------------------|
| HU-01 | Inicio de sesión (JWT + roles) | 5 | `POST /api/v1/auth/login` devuelve token + rol; credenciales malas → 401 |
| HU-02 | Crear cuenta de Técnico | 5 | `POST /api/v1/users` (rol supervisor) crea técnico; usuario duplicado → 409 |
| HU-04 | Registrar ubicación técnica | 3 | `POST /api/v1/technical-locations` crea y lista ubicaciones |
| HU-05 | Crear OT con pasos | 8 | `POST /api/v1/work-orders` crea OT con 3 pasos fijos + pasos propios; turno calculado |
| HU-06 | Validación PM01 obligatorio | — | Sin paso PM01 → 400; PM01 sin tiempo planificado → 422 |
| HU-07 | Lista de OTs del turno (Técnico) | 5 | `GET /api/v1/work-orders` devuelve solo las del técnico en el turno vigente |
| HU-08 | Detalle de OT | 3 | `GET /api/v1/work-orders/{id}` con pasos y estado de avance; acceso ajeno → 403 |
| HU-09 | Registrar cierre de paso PM01 | 8 | `POST /api/v1/work-orders/{id}/steps/{step_id}/closures`; recierre → 409; OT ajena → 403; todos los PM01 cerrados → OT `notified` |

Colchón descartable sin romper el objetivo: HU-03 (deshabilitar técnico), HU-10 (indicador de avance para supervisor).

## Capacidad y supuestos
- Horas disponibles reales: _(rellenar)_
- Stack del sprint: 100% Python/FastAPI — sin trabajo de Flutter.
- Base de datos PostgreSQL local ya instalada y accesible.
- Riesgos conocidos al empezar: alcance alto para 2 días; primera vez estructurando arquitectura hexagonal a mano.

## Desglose técnico (Sprint Backlog)

### Infraestructura (antes de HU-01)
- [ ] `backend/pyproject.toml` con dependencias
- [ ] `backend/src/config.py` (Settings con pydantic-settings)
- [ ] `backend/src/adapters/outbound/postgres/database.py` (engine async, `get_session`, `Base`)
- [ ] `backend/src/main.py` (app FastAPI + CORS + routers vacíos)
- [ ] Alembic inicializado

### HU-01 — Login
- [ ] `domain/models/user.py` (dataclass User, enums Role, UserStatus)
- [ ] `domain/ports/user_repository.py` (interfaz)
- [ ] `domain/use_cases/authenticate.py`
- [ ] `adapters/inbound/password_utils.py` (bcrypt) y `jwt_utils.py` (firmar/verificar)
- [ ] `adapters/outbound/postgres/orm_models.py` (UserORM) + `user_repository.py`
- [ ] `adapters/inbound/routers/auth.py` (`POST /login`)
- [ ] `adapters/inbound/dependencies.py` (`get_current_user`, `require_supervisor`)
- [ ] Migración Alembic: tabla `users` + seed de un supervisor
- [ ] Prueba en Swagger: login OK / login 401

### HU-02 — Crear técnico
- [ ] `domain/use_cases/create_technician.py`
- [ ] `adapters/inbound/routers/users.py` (`POST /users`)
- [ ] Prueba: crear técnico OK / usuario duplicado 409

### HU-04 — Ubicación técnica
- [ ] `domain/models/technical_location.py`
- [ ] `domain/ports/technical_location_repository.py`
- [ ] `domain/use_cases/register_technical_location.py`
- [ ] ORM `TechnicalLocationORM` + repo + router `technical_locations.py`
- [ ] Migración Alembic: tabla `technical_locations`
- [ ] Prueba: crear + listar

### HU-05 / HU-06 — Crear OT
- [ ] `domain/models/work_order.py` (WorkOrder, OTStep, StepClosure, enums, excepciones)
- [ ] `domain/models/shift.py` (`SHIFT_WINDOWS`, `get_current_shift`)
- [ ] `domain/ports/work_order_repository.py`
- [ ] `domain/use_cases/create_work_order.py` (pasos fijos + validación PM01)
- [ ] ORM `WorkOrderORM`, `OTStepORM`, `StepClosureORM` + repo
- [ ] `adapters/inbound/routers/work_orders.py` (`POST /work-orders`, schemas Pydantic)
- [ ] Migración Alembic: tablas `work_orders`, `ot_steps`, `step_closures`
- [ ] Prueba: crear OK / sin PM01 → 400 / PM01 sin tiempo → 422

### HU-07 / HU-08 — Listar y ver OT
- [ ] `domain/use_cases/get_shift_work_orders.py`
- [ ] `domain/models/work_order.py`: `compute_engagement_state`
- [ ] `domain/use_cases/record_ot_view.py`
- [ ] Router: `GET /work-orders`, `GET /work-orders/{id}`
- [ ] Prueba: lista filtrada por turno / detalle / acceso ajeno → 403

### HU-09 — Cierre de paso
- [ ] `domain/use_cases/register_step_closure.py` (409 recierre, 403 OT ajena, transición a `notified`)
- [ ] Router: `POST /work-orders/{id}/steps/{step_id}/closures`
- [ ] Exception handlers en `main.py`
- [ ] Prueba: cierre OK / recierre 409 / OT ajena 403 / OT pasa a `notified`

## Puntos restantes al iniciar: 37
