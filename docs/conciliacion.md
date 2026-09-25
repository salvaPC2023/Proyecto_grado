# Conciliación entre metodología, arquitectura y base de datos

Estado de coherencia de los tres pilares del proyecto. Es el **único lugar** donde se
registra qué no cuadra y cómo se resuelve. Sustituye las notas sueltas de
"pendiente de conciliar" de `arquitectura/quality-attributes.md` y `arquitectura/justificante.md`.

**Principio de resolución:** la **base de datos** ([`Base de Datos/Query.txt`](Base%20de%20Datos/Query.txt)) es la fuente
de verdad, salvo cuando carece de algo que un requisito necesita; en ese caso la decisión
es *añadir la columna* o *relajar el requisito*, y queda marcada como **DECISIÓN** abajo.

Leyenda de estado: ✅ resuelto y aplicado · ✍️ resuelto, falta aplicar en los docs ·
❓ **necesita tu decisión** (ver §4).

---

## 1. Base de datos ↔ requisitos (RF / HU / backlog)

| # | Tema | Requisito / backlog dice | La base de datos dice | Resolución | Estado |
|---|---|---|---|---|---|
| D-01 | **Estados de la OT** | RF-20 "estado *liberada*"; RF-27 "estado *notificada*"; backlog HU-05 `released`, HU-09 `notified` | `estatus_ot_enum = ('asignada','en_progreso','cerrada')` | Usar los nombres de la BD. Mapa: *liberada→asignada*, *notificada→cerrada*, y `en_progreso` = hay al menos un cierre de paso registrado y no todos los PM01 cerrados. Reescribir RF-20, RF-27, RF-29, HU-05, HU-09 y la matriz de `historias-usuario.md`. | ✅ |
| D-02 | **Marca de "primera visualización"** | RF-23 "registrar el momento de la primera vez que el Técnico abre la OT"; RF-29 / HU-10 indicador "*no vista / vista* / en ejecución / cerrada" | `Ordenes_de_trabajo` **no tiene** columna de visualización ni de fecha de creación | Ver **DECISIÓN D1** (§4). | ✅ |
| D-03 | **Número de turno de la OT** | RF-19 "calcular el número de turno según la hora de creación"; RF-21 / HU-07 "turno vigente"; backlog fija T1 23–07 / T2 07–15 / T3 15–23 | `Ordenes_de_trabajo` **no tiene** `turno` ni `fecha_creacion`. `Supervisores` y `Grupo` tienen `horario_entrada`/`horario_salida` **variables** por entidad | Ver **DECISIÓN D2** (§4). | ✅ |
| D-04 | **Pasos fijos y numeración** | RF-16 "anteponer 3 pasos fijos de seguridad"; HU-05 "pasos numerados" | `Pasos_de_ots` tiene `descripcion, estatus, horas_planificadas, clave_control`. **No tiene** `posicion` ni marca `es_fijo` | Ver **DECISIÓN D3** (§4). | ✅ |
| D-05 | **Campos del cierre de paso** | RF-25 "duración real, descripción, clave de desviación y **respuesta a la pregunta de seguridad**"; HU-09 "desviación `PM01 Executed` / `PM01 Not Executed`" | `Cierres_paso_ot`: `tiempo_real_trabajado`, `descripcion_trabajo_realizado`, `resultado_trabajo=('ejecutado','no_ejecutado')`, `trabajo_finalizado` (bool), `sin_trabajo_realizado` (bool), `fecha_hora_notificacion` | Renombrar en RF/HU: "clave de desviación" → `resultado_trabajo` (`ejecutado`/`no_ejecutado`). La "**pregunta de seguridad**" no tiene columna → ver **DECISIÓN D3** (§4). | ✅ |
| D-06 | **Datos al crear la OT** | RF-14 / HU-05: "tipo de orden, ubicación técnica, técnico asignado, **grupo planificador**, estado de la instalación, fechas, prioridad" | `Ordenes_de_trabajo`: `tipo_de_orden, ubicacion_tecnica_id, tecnico_asignado_id, descripcion` (NOT NULL), `prioridad`, `estatus_instalacion` (**booleano**), `fecha_inic_planif`, `fecha_fin_planif`. **No hay** `grupo_planificador` | Reescribir RF-14 / HU-05: quitar "grupo planificador"; añadir "**descripción de la OT**" (obligatoria); "estado de la instalación" es booleano (en marcha / detenida). | ✅ |
| D-07 | **Datos al crear el Técnico** | RF-05 / HU-02: "indicando **nombre y usuario**" | `tecnicos`: `grupo_id` NOT NULL, `profesion` NOT NULL, `especializacion`. `usuarios`: `apellido_paterno` NOT NULL, `numero_celular`, `fecha_nacimiento`, `genero` | Reescribir RF-05 / HU-02: "indicando nombre, apellidos, usuario, **grupo** y **profesión** (`eléctrico` / `mecánico` / `electromecánico`)". | ✅ |
| D-08 | **Representación del rol** | RF-03 "entregar el rol"; RF-04 "Administrador, Supervisor o Técnico"; RF-10 autorización por rol | `usuarios` **no tiene** columna `rol`. El rol se deduce de estar en `supervisores` o en `tecnicos`. **No hay** representación de Administrador | El rol se **deriva** de la pertenencia a `supervisores` / `tecnicos`; sin pertenencia = Administrador (rol futuro, E5). Documentar la derivación como regla de dominio. Sin cambio de BD. | ✅ |
| D-09 | **Autenticación** | RNF-01 "hash bcrypt"; backlog HU-01 "token JWT" | `usuarios` tiene **`auth_user_id`** (proveedor externo, nullable) **y** `password_hash` NOT NULL | Ver **DECISIÓN D4** (§4). | ✅ |
| D-10 | **Cambio de contraseña obligatorio** | No hay RF | `usuarios.debe_cambiar_password` BOOLEAN DEFAULT TRUE | Añadir RF: "El sistema debe exigir el cambio de la contraseña por defecto en el primer inicio de sesión". | ✅ |
| D-11 | **Unicidad de ubicación técnica** | RF-12 "impedir combinación repetida de los cuatro niveles" | `Ubicaciones_tecnicas` **no tiene** restricción `UNIQUE`; solo `sector` es NOT NULL | Recomendado: añadir `UNIQUE(sector, subsector, sistema, subsistema)` a la BD. Si no, RF-12 se cumple solo con validación en la aplicación (menos garantía) → nota en RF-12. | ⏳ (recomendación a la BD) |
| D-12 | **Módulo Comunicados** | rf-rnf.md y el backlog **no lo mencionan** (no hay RF ni épica). QAS-06 lo usa como *ejemplo* de "módulo nuevo"; `justificante.md` lo lista como rebanada | `Comunicados` es una **tabla completa** (supervisor→técnico, texto/imagen, `fecha_expiracion`, check "no vacío") | Ver **DECISIÓN D5** (§4). | ✅ |
| D-13 | **Terminología estandarizar / normalizar** | Título del producto y módulo: "**Estandarización**". RF-30…36, HU-11, QAS y `justificante.md`: mezclan "**normalizar**" | Unificar en "**estandarizar / estandarización**" en todos los documentos (es el término del informe). "Normalizar" solo si el informe lo distingue explícitamente. | ✅ |
| D-14 | **Ventanas de turno fijas** | Backlog HU-05: "T1 23:00–07:00, T2 07:00–15:00, T3 15:00–23:00" | `Supervisores`/`Grupo` modelan horarios **variables** por entidad | Depende de **DECISIÓN D2** (§4). Si el turno se deriva del horario del grupo, la tabla fija del backlog se elimina. | ✅ |
| D-15 | **`resumen` de rf-rnf.md** | Sección "Resumen" con erratas ("Accesso", "Gestiósn", "Estandsarización") | — | Corregir erratas. Los conteos (10/19/7/5/4 = 45) son correctos. | ✅ |

---

## 2. Metodología ↔ arquitectura

| # | Tema | Metodología dice | Arquitectura dice | Resolución | Estado |
|---|---|---|---|---|---|
| M-01 | **Estructura de carpetas del backend** | `definition-of-done.md` → "la lógica vive en `domain/`, adaptadores en `adapters/outbound/`". `trello-cards.md` (CH-01…05 y checklists de HU) usan `backend/src/domain/`, `adapters/inbound/routers/`, `adapters/outbound/postgres/` (estructura **plana** del proyecto de referencia) | `justificante.md` §2: **hexagonal + vertical slicing** → `backend/src/funcionalidades/<x>/{dominio,aplicacion,infraestructura}` + `compartido/` | Actualizar la DoD (sección "Backend") y las tareas de `trello-cards.md` a la estructura por rebanadas. | ✅ |
| M-02 | **Estructura de carpetas del móvil** | `definition-of-done.md` → "MVVM … `core/router.dart`". `trello-cards.md` usa `presentation/screens/`, `data/remote/`, `domain/repositories/`, `core/` | `justificante.md` §3: **Clean Architecture + MVVM** (por capas; no menciona vertical slicing en el móvil) | Confirmar que el móvil va **por capas** (`lib/domain`, `lib/data`, `lib/presentation`, `lib/core`), no por rebanadas. Dejarlo explícito en `justificante.md` §3 y alinear DoD/trello. | ✅ |
| M-03 | **RNF-12 vs. arquitectura** | RNF-12: "el servidor separa la lógica de los detalles de framework y BD; el móvil separa interfaz de lógica" | hexagonal + vertical slicing / Clean + MVVM | Coherente. Opcional: RNF-12 puede nombrar los estilos para trazar mejor. | ✅ |
| M-04 | **Nombre "Scrumban"** | `metodologia-planificacion.md` §6 y `trello-setup.md` lo marcan como término fuera de la bibliografía | — | Coherente (ambos lo advierten). | ✅ |

---

## 3. Inconsistencias internas de la metodología

| # | Tema | Detalle | Resolución | Estado |
|---|---|---|---|---|
| I-01 | **Fechas del plan de sprints** | `sprint-plan.md` fija inicio 2026-09-08 y entrega 2026-09-14, sprints de 2 días. `vision-y-roles.md` y `user-story-map.md` dicen "release 14-sep". Hoy es 2026-09-10 y **no hay código ni actas de sprint** | Ver **DECISIÓN D6** (§4): fecha de entrega real → re-fechar `sprint-plan.md`, `vision-y-roles.md` §2, `user-story-map.md`. | ✅ |
| I-02 | **Criterios de las HU con nombres del proyecto de referencia** | El backlog usa `technician`, `released`, `notified`, `PM01 Executed/Not Executed`, códigos HTTP concretos | Alinear a los nombres de la BD (D-01, D-05) y dejar los códigos HTTP solo como "detalle de implementación" | ✅ |
| I-03 | **`historias-usuario.md` §6–§7** | Dice "la matriz de la **número 4**", "Definition of Done (**número 5**)" (reemplazo de `§`) | Cambiar a "**sección 4**", "**sección 5**" | ✅ |
| I-04 | **`product-backlog.md` metadatos** | "Última actualización: 2026-09-07" (desactualizado); "Trazabilidad" menciona estado `notified` | Actualizar fecha; `notified` → `cerrada` | ✅ |
| I-05 | **Nombre de la épica E5** | `product-backlog.md`: "Panel administrativo y analítica"; `rf-rnf.md`: "Administración"; otros: "Panel administrativo (futuro)" | Unificar en "**E5 · Administración y analítica (trabajo futuro)**" | ✅ |
| I-06 | **Módulo de Comunicados en la arquitectura** | `justificante.md` §2 lista `comunicados` como rebanada; QAS-06 lo usa de ejemplo; pero no hay épica/RF | Depende de **DECISIÓN D5**. Si es futuro, la rebanada `comunicados` se marca "(futura)" en `justificante.md`. | ✅ |

---

## 4. Decisiones tomadas

| # | Decisión | Resolución (2026-09-10) |
|---|---|---|
| **D1** | Indicador de avance / "primera visualización" (D-02) | **La primera vez que el Técnico abre el detalle, la OT pasa a `en progreso`.** Ese cambio de estado es el registro de "primera visualización" (cumple RF-23 sin columna nueva). El avance = el enum `estatus` (`asignada` / `en progreso` / `cerrada`). |
| **D2** | Modelo de turno (D-03, D-14) | **Sin columna de turno.** RF-19 → el sistema registra la hora de cada cierre y **señala** los que el Técnico hace fuera del `horario_entrada`/`horario_salida` de su Grupo (no los bloquea). RF-21 → el Técnico ve solo las OTs asignadas a él. RF-29 → el Supervisor ve las OTs **de su grupo**. El Supervisor no se limita por horario; sus acciones fuera de horario quedan registradas. Se elimina la tabla de ventanas fijas T1/T2/T3. |
| **D3** | Pasos fijos (D-04) | **Mantener 3 pasos de seguridad autogenerados, sin numerar y sin marca `es_fijo`.** RF-16 reescrito sin "anteponer/numerados". Sin cambio de BD. |
| **D3** | Pregunta de seguridad (D-05) | **Se elimina de RF-25.** El cierre registra: duración real trabajada, descripción, `resultado_trabajo` (`ejecutado`/`no ejecutado`), `trabajo_finalizado`, `sin_trabajo_realizado`. Sin cambio de BD. |
| **D4** | Autenticación (D-09) | **Propia:** sesión firmada (JWT) + `password_hash` bcrypt. `auth_user_id` queda **reservado, sin uso**, para un SSO futuro. RNF-01…RNF-04 se mantienen. |
| **D5** | Módulo Comunicados (D-12) | **Trabajo futuro:** épica **E6 · Comunicados**, marcada `Won't (ahora)`. RF-46…RF-50 listados; HU-20 y HU-21 en el backlog fuera de sprints. La rebanada `comunicados` se cita como futura. |
| **D6** | Fecha de entrega (I-01) | **Resuelto:** objetivo **última semana de noviembre 2026**, límite **primera semana de diciembre**. Plan de 6 sprints (9,5 semanas, 11 sep → ~18 nov) + ~1 semana de cierre. `sprint-plan.md` reescrito. |
| **D7** | Unicidad de ubicación técnica (D-11) | **Recomendación a la BD:** añadir `UNIQUE(sector, subsector, sistema, subsistema)` a `Ubicaciones_tecnicas`. Si no se añade, RF-12 se cumple solo con validación en la aplicación. |

### Cambios recomendados a la base de datos (opcionales, no bloqueantes)

| # | Recomendación | Motivo |
|---|---|---|
| BD-1 | `UNIQUE(sector, subsector, sistema, subsistema)` en `Ubicaciones_tecnicas` | Garantiza RF-12 a nivel de datos (D-07). |
| BD-2 | `fecha_creacion TIMESTAMP DEFAULT now()` en `Ordenes_de_trabajo` | Deja constancia de la hora de creación para la regla de "acción fuera de horario" del Supervisor (D2). Los cierres ya tienen `fecha_hora_notificacion`. |

---

## 5. Cambios aplicados en esta pasada

_(se completa al aplicar las resoluciones ✍️ y las decisiones de §4)_

| Fecha | Cambio | Archivos |
|---|---|---|
| 2026-09-10 | Creación de este documento; auditoría inicial de coherencia | `conciliacion.md` |
| 2026-09-10 | Estados de la OT → `asignada` / `en progreso` / `cerrada` (D-01) | `rf-rnf.md`, `product-backlog.md`, `historias-usuario.md`, `user-story-map.md` |
| 2026-09-10 | RF-14/HU-05: quitar "grupo planificador", añadir "descripción" y "estado de la instalación" (D-06) | `rf-rnf.md`, `product-backlog.md`, `historias-usuario.md` |
| 2026-09-10 | RF-05/HU-02: crear Técnico con nombre, apellidos, usuario, grupo y profesión (D-07) | `rf-rnf.md`, `product-backlog.md`, `historias-usuario.md` |
| 2026-09-10 | RF-06: exigir cambio de contraseña en el primer inicio de sesión (D-10) | `rf-rnf.md` |
| 2026-09-10 | RF-16: 3 pasos de seguridad autogenerados sin numerar (D-04) | `rf-rnf.md`, `product-backlog.md`, `historias-usuario.md` |
| 2026-09-10 | RF-19/RF-21/RF-29: modelo de turno por horario de grupo; sin columna de turno (D-03) | `rf-rnf.md`, `product-backlog.md`, `historias-usuario.md` |
| 2026-09-10 | RF-23: abrir el detalle pasa la OT a `en progreso` (D-02) | `rf-rnf.md`, `historias-usuario.md` |
| 2026-09-10 | RF-25/HU-09: campos del cierre según `Cierres_paso_ot`; se quita "pregunta de seguridad" (D-05) | `rf-rnf.md`, `product-backlog.md`, `historias-usuario.md` |
| 2026-09-10 | Terminología unificada: "estandarizar / estandarización" (D-13) | `rf-rnf.md`, `product-backlog.md`, `historias-usuario.md`, `user-story-map.md`, `vision-y-roles.md`, `sprint-plan.md`, `quality-attributes.md`, `trello-cards.md` |
| 2026-09-10 | Épica E5 → "Administración y analítica"; nueva épica E6 · Comunicados (Won't); RF-46…50; HU-20/HU-21 (D-12) | `rf-rnf.md`, `product-backlog.md`, `historias-usuario.md`, `user-story-map.md`, `vision-y-roles.md`, `metodologia-planificacion.md`, `trello-setup.md`, `quality-attributes.md` |
| 2026-09-10 | Autenticación propia (JWT + bcrypt); `auth_user_id` reservado (D-09) | `quality-attributes.md` |
| 2026-09-10 | Rol derivado de pertenencia a `Supervisores` / `Tecnicos` (D-08) | `rf-rnf.md`, `vision-y-roles.md` |
| 2026-09-10 | DoD backend → estructura hexagonal + vertical slicing; corregidos los números de RNF transversales (M-01) | `definition-of-done.md` |
| 2026-09-10 | `sprint-plan.md`: aviso de fechas por re-confirmar (I-01, D-06) | `sprint-plan.md` |
| 2026-09-10 | "número N" → "sección N" | `historias-usuario.md` |
| 2026-09-10 | Plan de 6 sprints con duración 1–3 semanas (7 sep → ~25 nov); E4 (offline) integrado en el Sprint 2; redacción de capítulos en paralelo (D-06) | `sprint-plan.md` |
| 2026-09-10 | Alcance ampliado: E4 → Must; E6 · Comunicados → Should (Sprint 5); nueva E7 · Importación y exportación → Should (Sprint 4); E5 se queda con lo administrativo/analítico como futuro | `product-backlog.md`, `historias-usuario.md`, `rf-rnf.md`, `vision-y-roles.md`, `user-story-map.md`, `metodologia-planificacion.md` |
| 2026-09-10 | rf-rnf.md: módulo 5 → 3 RF; nuevo módulo 6 Importación y exportación (RF-45…48); Comunicados → módulo 7 (RF-49…53). Total RF 53 | `rf-rnf.md` |
| 2026-09-10 | Historias nuevas HU-22/23/24 (E7); HU-19 (import) absorbida en HU-22; HU-20/21 pasan a comprometidas | `historias-usuario.md`, `product-backlog.md` |
| 2026-09-10 | metodologia §6: "sprints de 2 días" → "duración variable 1–3 semanas" (encaja con Cohn) | `metodologia-planificacion.md` |
| 2026-09-10 | user-story-map: mapa re-bandado a 6 sprints; QAS-06: ejemplo de "módulo nuevo" pasa a E5 (analítica) | `user-story-map.md`, `quality-attributes.md` |

### Pendiente de aplicar

| # | Acción | Motivo |
|---|---|---|
| P-1 | Reescribir las rutas de archivo de cada tarea en `trello-cards.md` a `funcionalidades/<x>/{dominio,aplicacion,infraestructura}` | Hoy hay una nota al inicio del archivo; el detalle por tarjeta sigue en estructura plana (M-01). |
| ~~P-2~~ | ~~Re-fechar los documentos de plan~~ | Hecho (D-06 resuelto). |
| P-3 | Corregir erratas de la sección "Resumen" de `rf-rnf.md` si reaparecen | El autor edita ese archivo a mano (D-15). |
