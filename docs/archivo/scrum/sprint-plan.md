# Plan de Sprints — Maintenance App

**Inicio del desarrollo:** 2026-09-07 · **Fin de sprints:** ~2026-11-18 · **Entrega objetivo:** última semana de noviembre 2026 (límite: primera semana de diciembre)
**Duración de sprint:** 1 a 3 semanas según el módulo · **Sprints:** 0 (preparación) + 6

## Contexto (para el informe)

El desarrollo se reinició el 2026-09-07 tras el rechazo de la metodología SDD
(Spec-Driven Development) por el tribunal. Se adoptó **Scrum + Kanban (Scrumban)**. El
código del intento previo se conserva **solo como referencia técnica**; todo el código de
este repositorio se escribe de nuevo, por historia de usuario, dentro de los sprints aquí
planificados.

Los sprints duran entre 1 y 3 semanas, dentro del rango que recomienda Cohn (*Agile
Estimating and Planning*: iteraciones de 1 a 4 semanas).

## Roles (adaptación para proyecto unipersonal) {#roles}

| Rol Scrum | Asignación | Justificación |
|---|---|---|
| Product Owner | Salvador Patty, con validación del supervisor de Mantenimiento de ESPODI como cliente | El reglamento de grado no contempla un PO externo; el tesista prioriza el backlog a partir del relevamiento con el cliente real y lo valida con el docente tutor. |
| Scrum Master | Salvador Patty | En equipos unipersonales el tesista facilita su propio proceso; el tutor actúa como asesor de proceso. |
| Development Team | Salvador Patty | Único desarrollador. |

Esta adaptación se declara explícitamente y es una práctica aceptada en proyectos de
grado individuales.

## Capacidad

Un desarrollador a tiempo parcial. La velocidad real se mide al cerrar el Sprint 1 y se
ajusta el resto del plan.

---

## Sprint 0 — Preparación  *(7 – 10 sep, hecho)*

Definición del Product Backlog y priorización · diseño de la arquitectura (hexagonal +
vertical slicing en el backend; Clean Architecture + MVVM en el frontend) · repositorio
Git y estructura de carpetas · esquema inicial de la base de datos (PostgreSQL) ·
variables de entorno y conexión · **conciliación** metodología / arquitectura / BD
(ver [`../conciliacion.md`](../conciliacion.md)).

---

## Sprint 1 — Base técnica + autenticación y usuarios  *(11 – 23 sep · 1,5 semanas)*

**Sprint Goal:** implementar la base técnica del sistema y el módulo de autenticación y
de usuarios (tema **E1**).

- Esqueleto ejecutable del backend (FastAPI + PostgreSQL, estructura por rebanadas).
- Autenticación propia: inicio de sesión con sesión firmada (JWT) + `password_hash` bcrypt; rol derivado de la pertenencia a `Supervisores` / `Tecnicos`.
- Gestión de cuentas: crear Técnico (nombre, apellidos, usuario, grupo, profesión), cambio de contraseña en el primer inicio, deshabilitar cuenta.
- Registro de ubicaciones técnicas.
- Historias: **HU-01, HU-02, HU-03, HU-04**.

**Entregable demostrable:** colección de peticiones (Swagger) que recorre login → crear
técnico → registrar ubicación técnica contra PostgreSQL.

---

## Sprint 2 — Gestión de OTs + operación sin conexión  *(24 sep – 14 oct · 3 semanas)*

**Sprint Goal:** desarrollar el módulo de gestión de Órdenes de Trabajo (tema **E2**) e
integrar la operación sin conexión (tema **E4**).

- Crear OT (descripción, ubicación, técnico, tipo, estado de instalación, fechas, prioridad); 3 pasos de seguridad autogenerados; validación de PM01.
- Listar OTs asignadas al Técnico; detalle de OT (la primera apertura pasa la OT a `en progreso`); dashboard de OTs del grupo para el Supervisor con su estado.
- Registrar cierre de paso PM01 (duración, descripción, resultado, estado del trabajo); transición a `cerrada` cuando todos los PM01 quedan cerrados; registro de la hora y aviso de "fuera de horario del grupo".
- **Offline:** cola local de cierres (Drift), indicador de pendientes, sincronización automática al reconectar con identificadores idempotentes (ver QAS-01, QAS-02, QAS-09).
- Pantallas Flutter del flujo Técnico y del flujo Supervisor para este módulo.
- Historias: **HU-05, HU-06, HU-07, HU-08, HU-09, HU-10, HU-14, HU-15**.

**Entregable demostrable:** app en dispositivo recorriendo el flujo completo Supervisor →
Técnico, incluido el registro de un cierre en modo avión y su posterior sincronización.

---

## Sprint 3 — Estandarización de descripciones con LLM  *(15 – 21 oct · 1 semana)*

**Sprint Goal:** desarrollar el módulo de estandarización de descripciones mediante un LLM
(tema **E3**).

- Endpoint de estandarización + adaptador de salida (OpenAI `gpt-4o-mini`) con timeout de 8 s.
- Panel en el formulario de cierre para revisar y editar el texto estandarizado.
- Degradación tolerante: si el LLM falla o no hay conexión, se continúa con el texto original sin bloquear el cierre (QAS-04).
- Historias: **HU-11, HU-12, HU-13**.

**Entregable demostrable:** cierre de un paso con una descripción real de termografía /
vibración estandarizada, editada y enviada; y el mismo flujo con el LLM caído.

---

## Sprint 4 — Importación y exportación de datos  *(22 oct – 4 nov · 2 semanas)*

**Sprint Goal:** implementar los mecanismos de importación y exportación de datos
(tema **E7**).

- Importar técnicos y ubicaciones técnicas desde archivos Excel (validación de filas, reporte de errores).
- Exportar el listado de OTs (con filtros) a Excel / CSV.
- Exportar el reporte de cierres de un periodo a Excel / CSV.
- Historias: **HU-22, HU-23, HU-24**.

**Entregable demostrable:** carga de un Excel de técnicos de prueba y descarga de un
reporte de OTs del periodo.

---

## Sprint 5 — Envío de comunicados  *(5 – 11 nov · 1 semana)*

**Sprint Goal:** implementar los mecanismos de envío de comunicados (tema **E6**).

- El Supervisor envía un comunicado (texto y/o imagen) a un Técnico o a todo su grupo.
- Fecha de expiración; los comunicados vencidos dejan de mostrarse y su imagen se elimina.
- El Técnico ve los comunicados vigentes de su Supervisor.
- Historias: **HU-20, HU-21**.

**Entregable demostrable:** envío de un comunicado con imagen y su expiración automática.

---

## Sprint 6 — Pruebas con usuarios finales  *(12 – 18 nov · 1 semana)*

**Sprint Goal:** validar el sistema con usuarios finales (supervisor y técnicos de
Mantenimiento de ESPODI o perfiles equivalentes).

- Guion de pruebas por rol; ejecución acompañada; registro de incidencias y de tiempos.
- Correcciones de alta prioridad detectadas en las pruebas.
- Medición de las condiciones de satisfacción del release (`vision-y-roles.md` §2) y de las métricas de flujo (cycle time, throughput).

**Entregable demostrable:** informe de pruebas con usuarios + lista de incidencias
resueltas / diferidas.

---

## Cierre — 19 nov en adelante  *(consolidación, no es sprint)*

- Gráficos burndown de los 6 sprints y diagrama de flujo acumulado.
- Actas finales de Review y Retrospectiva.
- Export del Product Backlog completo y capturas del tablero Scrumban como anexos.
- Redacción final del Capítulo 3 (Marco Metodológico) y del Capítulo 4 (resultados).
- Ensayo de defensa.

> **La redacción de los Capítulos 3 y 4 se hace en paralelo, sprint a sprint**, no toda al
> final. El Capítulo 3 se apoya en los documentos de `docs/scrum/`; el Capítulo 4 se llena
> con la evidencia de cada Review. Así el periodo de cierre es ~1 semana y la entrega cae
> en la última semana de noviembre, con margen hasta la primera de diciembre.

---

## Resumen de duración

| | Semanas |
|---|---:|
| Sprint 1 | 1,5 |
| Sprint 2 (OTs + offline) | 3 |
| Sprint 3 | 1 |
| Sprint 4 | 2 |
| Sprint 5 | 1 |
| Sprint 6 | 1 |
| **Total de sprints** | **9,5** |
| Cierre / consolidación | ~1 |
| **Total** | **~10,5** (7 sep → ~25 nov) |

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Curva de aprendizaje de Flutter/Dart (experiencia previa en JS) | El Sprint 1 es casi todo backend (Python); la app se aborda en el Sprint 2 con 3 semanas de margen; código de referencia disponible |
| El Sprint 2 concentra OTs + offline (lo más complejo) | Es el sprint más largo (3 sem); el offline se prototipa primero (cola idempotente, ver QAS) antes de las pantallas |
| Deslizamiento acumulado que empuje a diciembre | Redacción de capítulos en paralelo; Sprint 4 (import/export) es el primer candidato a recortar a 1,5 semanas; las pruebas con usuarios pueden solaparse con la consolidación |
| Costos/latencia del LLM | `gpt-4o-mini` (bajo costo); timeout 8 s con degradación (HU-13) |
