# Product Backlog — Maintenance App

**Producto:** Aplicación móvil con integración de un modelo de lenguaje de gran escala para la gestión de órdenes de trabajo en el Departamento de Mantenimiento
**Última actualización:** 2026-09-10
**Product Owner:** Salvador Patty Camacho (rol adaptado — ver [sprint-plan.md](sprint-plan.md#roles))

**Discovery previo:** este backlog deriva de [Visión y roles de usuario](discovery/vision-y-roles.md)
(visión del producto + condiciones de satisfacción del release + modelado de roles) y del
[Mapa de historias](discovery/user-story-map.md) (espina dorsal + línea de release). Ver esos
documentos para la justificación del alcance.

> **Terminología:** en este documento "épica" (E1–E5) se usa como sinónimo operativo de
> *tema (theme)* en el sentido de Cohn, *User Stories Applied*: una colección de historias
> relacionadas. La distinción *epic* / *theme* de Cohn está en
> [`metodologia-planificacion.md`](metodologia-planificacion.md) §3.

---

## Cómo leer este backlog

- **Prioridad (MoSCoW):** `Must` = imprescindible para la entrega · `Should` = importante, entra si hay capacidad · `Could` = deseable · `Won't (ahora)` = fuera del alcance de esta entrega, queda registrado como trabajo futuro.
- **Estimación:** puntos de historia (escala Fibonacci: 1, 2, 3, 5, 8, 13). Miden esfuerzo relativo, no horas.
- **Estado:** `Backlog` → `Sprint` → `En curso` → `Hecho` (cumple la [Definition of Done](definition-of-done.md)).
- Los criterios de aceptación usan formato Gherkin (Dado / Cuando / Entonces). Los requerimientos no funcionales aplicables se listan como criterios transversales y forman parte de la Definition of Done.

---

## Resumen de épicas

| # | Épica | Rol en el producto | Prioridad | Puntos | Estado |
|---|---|---|---|---:|---|
| E1 | Acceso y roles | Habilitador | Must | 13 | Backlog |
| E2 | **Gestión de Órdenes de Trabajo** | **Núcleo del proyecto** | **Must** | **34** | Backlog |
| E3 | Estandarización de descripciones con LLM | Diferenciador / aporte de la tesis | Must | 13 | Backlog |
| E4 | Operación sin conexión | Crítico (atributo de calidad nº 1); se desarrolla junto a E2 en el Sprint 2 | Must | 8 | Backlog |
| E5 | Administración y analítica | Extensión | Won't (ahora) | 16 | Backlog |
| E6 | Comunicados (supervisor → técnico) | Extensión comprometida — Sprint 5 | Should | 8 | Backlog |
| E7 | Importación y exportación de datos | Extensión comprometida — Sprint 4 | Should | 13 | Backlog |

> El catálogo de RF y RNF vive en [`rf-rnf.md`](rf-rnf.md) (y se anexa exportado del
> tablero). Los RF/RNF y las historias de este backlog son **dos vistas del mismo
> alcance**, no una derivada de la otra: el RF describe una capacidad del sistema; la
> historia es la unidad con la que el equipo planifica y verifica. La relación (muchos a
> muchos) y la matriz de cobertura Historia → RF están en
> [`historias-usuario.md`](historias-usuario.md). Los RNF son restricciones que aplican a
> las historias como condiciones transversales y como Definition of Done. Este documento
> presenta la estructura de temas y las historias priorizadas, con 2–3 historias completas
> por tema a modo ilustrativo.

---

## E1 — Acceso y roles  *(habilitador · Must · 13 pts)*

Sin autenticación ni roles no se puede asignar ni consultar una OT. Alcance mínimo:
lo necesario para que exista un Supervisor y un Técnico que operen sobre OTs.

| HU | Historia | Prioridad | Pts | Estado |
|---|---|---|---:|---|
| HU-01 | Como usuario, quiero iniciar sesión con usuario y contraseña, para acceder a la app según mi rol | Must | 5 | Backlog |
| HU-02 | Como Supervisor, quiero crear cuentas de Técnico de mi grupo, para poder asignarles OTs | Must | 5 | Backlog |
| HU-03 | Como Supervisor, quiero deshabilitar la cuenta de un Técnico, para revocar su acceso cuando deja el grupo | Should | 3 | Backlog |

### HU-01 — Inicio de sesión

**Dado** un usuario registrado y activo
**Cuando** envía usuario y contraseña correctos
**Entonces** el sistema devuelve un token JWT y el rol del usuario, y la app lo lleva a la pantalla inicial de su rol.

**Dado** un usuario con credenciales incorrectas o cuenta deshabilitada
**Cuando** intenta iniciar sesión
**Entonces** el sistema responde 401 y la app muestra "Usuario o contraseña incorrectos" sin revelar cuál de los dos falló.

Criterios transversales (RNF): contraseña almacenada con hash bcrypt; token firmado con secreto en variable de entorno; expiración configurable (por defecto 24 h); token guardado en almacenamiento seguro del dispositivo.

### HU-02 — Crear cuenta de Técnico

**Dado** un Supervisor autenticado
**Cuando** registra un Técnico con nombre, apellidos, usuario, grupo y profesión
**Entonces** el sistema crea la cuenta con rol Técnico, contraseña inicial por defecto (que deberá cambiar en el primer inicio de sesión), estado activo, y queda asociada al grupo y al Supervisor que la creó.

**Dado** un usuario que ya existe
**Cuando** el Supervisor intenta crear otro con el mismo usuario
**Entonces** el sistema responde 409 y no crea duplicado.

---

## E2 — Gestión de Órdenes de Trabajo  *(NÚCLEO · Must · 34 pts)*

Corazón del proyecto: estandarizar el registro y el seguimiento de las OT preventivas
(PM01), desde su creación por el Supervisor hasta el cierre del paso por el Técnico.

| HU | Historia | Prioridad | Pts | Estado |
|---|---|---|---:|---|
| HU-04 | Como Supervisor, quiero registrar una ubicación técnica (sector/subsector/sistema/subsistema), para poder referenciarla en las OTs | Must | 3 | Backlog |
| HU-05 | Como Supervisor, quiero crear una OT indicando ubicación técnica, técnico asignado, tipo, descripción, estado de la instalación, fechas y prioridad, para asignar trabajo de forma estandarizada | Must | 8 | Backlog |
| HU-06 | Como Supervisor, quiero que cada OT incluya obligatoriamente al menos un paso PM01 con horas planificadas mayores que cero, para garantizar que el mantenimiento preventivo quede registrado | Must | 5 | Backlog |
| HU-07 | Como Técnico, quiero ver la lista de OTs que me asignaron con su estado, para saber qué debo ejecutar | Must | 5 | Backlog |
| HU-08 | Como Técnico, quiero abrir el detalle de una OT y ver sus pasos, para conocer el alcance del trabajo | Must | 3 | Backlog |
| HU-09 | Como Técnico, quiero registrar el cierre de un paso PM01 con duración real, descripción del trabajo, resultado y estado del trabajo, para dejar constancia de lo ejecutado | Must | 8 | Backlog |
| HU-10 | Como Supervisor, quiero ver el estado de avance de las OTs de mi grupo (asignada / en progreso / cerrada), para dar seguimiento | Should | 2 | Backlog |

### HU-05 — Crear OT

**Dado** un Supervisor autenticado y una ubicación técnica existente
**Cuando** crea una OT con tipo de orden, ubicación técnica, técnico asignado, descripción, estado de la instalación (en marcha / detenida), fecha de inicio y fin planificadas, prioridad (1–4) y una lista de pasos
**Entonces** el sistema genera automáticamente los 3 pasos de seguridad, guarda la OT con estado `asignada` y devuelve el detalle completo con sus pasos.

**Dado** una solicitud de creación de OT
**Cuando** la lista de pasos no contiene ningún paso con clave de control `PM01`
**Entonces** el sistema responde 400 con "Se requiere al menos un paso PM01" y no crea la OT.  *(HU-06)*

**Dado** un paso `PM01` en la solicitud
**Cuando** su tiempo de intervención planificado es nulo o ≤ 0
**Entonces** el sistema responde 422 y no crea la OT.  *(HU-06)*

Criterios transversales (RNF): solo el rol Supervisor puede crear OTs (403 en otro caso); la prioridad se valida en rango 1–4; la descripción de la OT es obligatoria.

### HU-07 — Lista de OTs del turno (Técnico)

**Dado** un Técnico autenticado
**Cuando** consulta sus OTs
**Entonces** el sistema devuelve solo las OTs asignadas a él, cada una con su resumen (tipo, ubicación, prioridad, fechas, estado).

**Dado** un Técnico sin OTs asignadas
**Cuando** consulta sus OTs
**Entonces** el sistema devuelve una lista vacía y la app muestra un estado vacío explícito.

### HU-09 — Registrar cierre de paso PM01

**Dado** un Técnico autenticado y una OT asignada a él con un paso PM01 sin cerrar
**Cuando** envía duración real trabajada, descripción del trabajo realizado, resultado (`ejecutado` / `no ejecutado`), si el trabajo quedó finalizado y si no se realizó trabajo
**Entonces** el sistema guarda el cierre con su fecha, y si todos los pasos PM01 de la OT quedan cerrados, transiciona la OT a estado `cerrada`.

**Dado** un paso que ya tiene un cierre registrado
**Cuando** el Técnico intenta cerrarlo otra vez
**Entonces** el sistema responde 409 "El paso ya fue cerrado" y no duplica el cierre.

**Dado** una OT que no está asignada al Técnico que hace la solicitud
**Cuando** intenta registrar un cierre
**Entonces** el sistema responde 403.

Criterios transversales (RNF): el rol `supervisor` no puede registrar cierres (403); la duración real debe ser > 0; toda llamada asíncrona en la app muestra estado de carga.

---

## E3 — Estandarización de descripciones con LLM  *(diferenciador · Must · 13 pts)*

Aporte central de la tesis: convertir la descripción libre del técnico en un texto
estandarizado por secciones, sin alterar los datos reportados.

| HU | Historia | Prioridad | Pts | Estado |
|---|---|---|---:|---|
| HU-11 | Como Técnico, quiero que mi descripción libre se estandarice automáticamente en secciones, para mejorar la calidad y comparabilidad del registro | Must | 5 | Backlog |
| HU-12 | Como Técnico, quiero revisar y editar el texto estandarizado antes de enviarlo con el cierre, para corregir cualquier error de la estandarización | Must | 5 | Backlog |
| HU-13 | Como Técnico en zona sin señal o con el servicio caído, quiero poder guardar mi descripción original sin estandarizar, para no quedar bloqueado | Must | 3 | Backlog |

### HU-11 — Estandarizar descripción

**Dado** un Técnico redactando el cierre de un paso
**Cuando** solicita estandarizar un texto libre no vacío
**Entonces** el sistema devuelve el texto reorganizado en las secciones estándar (equipo intervenido, actividades realizadas, mediciones termográficas, mediciones de vibración, observaciones), preservando todos los valores numéricos y sin agregar diagnósticos ni conclusiones que el técnico no haya escrito.

### HU-13 — Degradación ante fallo del LLM

**Dado** que el servicio LLM responde con error o supera el tiempo máximo (8 s)
**Cuando** el Técnico solicita estandarizar
**Entonces** el sistema responde 503/504 y la app ofrece continuar con la descripción original, sin impedir el cierre del paso.

---

## E4 — Operación sin conexión  *(crítico · Must · 8 pts · Sprint 2, junto a E2)*

| HU | Historia | Prioridad | Pts | Estado |
|---|---|---|---:|---|
| HU-14 | Como Técnico sin conexión, quiero que el cierre de paso se guarde localmente en el dispositivo, para no perder el trabajo registrado | Should | 5 | Backlog |
| HU-15 | Como Técnico, quiero que los cierres pendientes se envíen automáticamente al recuperar la conexión, para no tener que reintentar manualmente | Should | 3 | Backlog |

---

## E5 — Administración y analítica  *(Won't ahora · 16 pts)*

Registrado como **trabajo futuro**. Incluye: rol Administrador, gestión de Supervisores,
dashboards de carga de trabajo por técnico, reporte por ubicación técnica y horas
trabajadas por técnico. (La importación/exportación de datos se movió al tema E7, que sí
entra en la entrega.)

| HU | Historia | Prioridad | Pts |
|---|---|---|---:|
| HU-16 | Como Administrador, quiero gestionar cuentas de Supervisor | Won't (ahora) | 8 |
| HU-17 | Como Supervisor, quiero un dashboard de carga de trabajo por técnico | Won't (ahora) | 5 |
| HU-18 | Como Supervisor, quiero un reporte de OTs por ubicación técnica | Won't (ahora) | 3 |

---

## E6 — Comunicados (supervisor → técnico)  *(Should · 8 pts · Sprint 5)*

Alcance comprometido. La base de datos ya prevé la tabla `Comunicados`. Cubre RF-49 a RF-53.

| HU | Historia | Prioridad | Pts |
|---|---|---|---:|
| HU-20 | Como Supervisor, quiero enviar un comunicado (texto y/o imagen) a un Técnico o a todo mi grupo, para transmitir instrucciones del turno | Won't (ahora) | 5 |
| HU-21 | Como Técnico, quiero ver los comunicados vigentes de mi Supervisor, para estar al día | Won't (ahora) | 3 |

---

## E7 — Importación y exportación de datos  *(Should · 13 pts · Sprint 4)*

Alcance comprometido. Cubre RF-45 a RF-48.

| HU | Historia | Prioridad | Pts |
|---|---|---|---:|
| HU-22 | Como Administrador, quiero importar técnicos y ubicaciones técnicas desde archivos Excel, para cargar el catálogo sin capturarlo a mano | Should | 5 |
| HU-23 | Como Supervisor, quiero exportar el listado de OTs (con los filtros aplicados) a Excel/CSV, para analizarlo o archivarlo | Should | 5 |
| HU-24 | Como Supervisor, quiero exportar el reporte de cierres de un periodo a Excel/CSV, para reportar el trabajo del grupo | Should | 3 |

---

## Trazabilidad con el informe aprobado

| Sección del informe | Elemento de este backlog |
|---|---|
| Objetivo específico "estandarizar el registro de OTs" | Épica E2 completa |
| Objetivo específico "notificar al personal técnico" | HU-07, estado `cerrada` en HU-09 |
| Objetivo específico "estandarizar descripciones con IA" | Épica E3 |
| Alcance 1.4 | E1 + E2 + E3 + E4 |
| Límite 1.5 (fuera de alcance) | E5 (parte administrativa) |
