# Historias de usuario

Presenta las historias de usuario (HU) del proyecto, qué son, cómo se relacionan con los requerimientos del informe (RF/RNF) y la matriz de cobertura entre ambos.

Fuente: Cohn, *User Stories Applied* y *Agile Estimating and Planning*.

## 1. Qué es una historia de usuario

Una historia de usuario describe una necesidad desde la perspectiva de quien la tiene, con el formato:

> **Como** \<rol\>, **quiero** \<meta\>, **para** \<beneficio\>.

No es una especificación cerrada: es un recordatorio para conversar. Cohn la resume en las
**tres C**:

- **Tarjeta (Card):** el enunciado corto, arriba.
- **Conversación:** el detalle se acuerda hablando con el cliente/usuario, no se escribe todo por adelantado.
- **Confirmación:** las condiciones de satisfacción (criterios de aceptación) que permiten decir que la historia está terminada.

Una buena historia cumple **INVEST**: Independiente, Negociable, Valiosa, Estimable, pequeña (Small) y verificable (Testable).

En este proyecto las historias viven en el [Product Backlog](product-backlog.md), con sus condiciones de satisfacción completas en formato "Dado / Cuando / Entonces".

---

## 2. Historia de usuario vs. requerimiento (RF / RNF)

Una HU no es un RF con más detalle, ni se deriva de un RF. Son dos vistas del mismo alcance:

| | Requerimiento funcional (RF) | Historia de usuario (HU) |
|---|---|---|
| Punto de vista | El sistema: "El sistema debe…" | El usuario: "Como \<rol\>, quiero…" |
| Para qué sirve | Documentar de forma estable **qué debe hacer** el sistema (análisis, contrato, informe) | Unidad con la que el equipo **planifica, conversa y verifica** el trabajo en los sprints |
| Nivel de detalle | Una afirmación de capacidad | El detalle son sus **condiciones de satisfacción**, no otro RF |
| Ciclo de vida | Catálogo relativamente fijo ([`rf-rnf.md`](rf-rnf.md)) | Se refina, divide y reordena sprint a sprint |

**Relación entre ambos:** es **muchos a muchos**. Una HU puede cubrir varios RF (p. ej.
HU-01 cubre RF-01 a RF-04) y un RF puede aparecer en varias HU (p. ej. RF-10, "restringir
según el rol", es transversal a casi todas). Ninguno "se convierte" en el otro; la matriz
de la sección 4 muestra qué RF quedan cubiertos por cada HU.

**Los RNF no se convierten en historias.** Son **restricciones**: se aplican a las
historias como condiciones transversales y forman parte de la Definition of Done (sección 5).

---

## 3. Catálogo de historias de usuario

Enunciado corto de cada historia. Condiciones de satisfacción completas: ver
[`product-backlog.md`](product-backlog.md).

| HU | Tema | Historia | Prioridad | Pts | Sprint |
|---|---|---|---|---:|---|
| HU-01 | E1 | Como usuario, quiero iniciar sesión con usuario y contraseña, para acceder según mi rol | Must | 5 | 1–2 |
| HU-02 | E1 | Como Supervisor, quiero crear cuentas de Técnico de mi grupo, para asignarles OTs | Must | 5 | 1, 3 |
| HU-03 | E1 | Como Supervisor, quiero deshabilitar la cuenta de un Técnico, para revocar su acceso | Should | 3 | 1 (colchón) |
| HU-04 | E2 | Como Supervisor, quiero registrar una ubicación técnica, para referenciarla en las OTs | Must | 3 | 1 |
| HU-05 | E2 | Como Supervisor, quiero crear una OT con ubicación, técnico, tipo, descripción, estado de la instalación, fechas y prioridad, para asignar trabajo estandarizado | Must | 8 | 1, 3 |
| HU-06 | E2 | Como Supervisor, quiero que cada OT tenga al menos un paso PM01 con horas planificadas mayores que cero, para garantizar el registro del preventivo | Must | (en HU-05) | 1 |
| HU-07 | E2 | Como Técnico, quiero ver las OTs que me asignaron, para saber qué ejecutar | Must | 5 | 1–3 |
| HU-08 | E2 | Como Técnico, quiero abrir el detalle de una OT y ver sus pasos, para conocer el alcance | Must | 3 | 1–2 |
| HU-09 | E2 | Como Técnico, quiero registrar el cierre de un paso PM01 con duración, descripción, resultado y estado del trabajo, para dejar constancia | Must | 8 | 1–2 |
| HU-10 | E2 | Como Supervisor, quiero ver el estado de avance de las OTs de mi grupo, para dar seguimiento | Should | 2 | 3 |
| HU-11 | E3 | Como Técnico, quiero que mi descripción libre se estandarice en secciones, para mejorar la calidad del registro | Must | 5 | 2 |
| HU-12 | E3 | Como Técnico, quiero revisar y editar el texto estandarizado antes de enviarlo, para corregir errores | Must | 5 | 2 |
| HU-13 | E3 | Como Técnico sin señal o con el servicio caído, quiero guardar mi descripción original, para no quedar bloqueado | Must | 3 | 2 |
| HU-14 | E4 | Como Técnico sin conexión, quiero que el cierre se guarde en el dispositivo, para no perder el trabajo | Should | 5 | 3 |
| HU-15 | E4 | Como Técnico, quiero que los cierres pendientes se envíen solos al recuperar la conexión, para no reintentar a mano | Should | 3 | 3 |
| HU-16 | E5 | Como Administrador, quiero gestionar cuentas de Supervisor | Won't (ahora) | 8 | futuro |
| HU-17 | E5 | Como Supervisor, quiero un dashboard de carga de trabajo por técnico | Won't (ahora) | 5 | futuro |
| HU-18 | E5 | Como Supervisor, quiero un reporte de OTs por ubicación técnica | Won't (ahora) | 3 | futuro |
| HU-20 | E6 | Como Supervisor, quiero enviar un comunicado (texto y/o imagen) a un Técnico o a todo mi grupo | Should | 5 | 5 |
| HU-21 | E6 | Como Técnico, quiero ver los comunicados vigentes de mi Supervisor | Should | 3 | 5 |
| HU-22 | E7 | Como Administrador, quiero importar técnicos y ubicaciones técnicas desde archivos Excel | Should | 5 | 4 |
| HU-23 | E7 | Como Supervisor, quiero exportar el listado de OTs a Excel/CSV | Should | 5 | 4 |
| HU-24 | E7 | Como Supervisor, quiero exportar el reporte de cierres de un periodo a Excel/CSV | Should | 3 | 4 |

---

## 4. Matriz de cobertura: Historia → RF

Qué RF de [`rf-rnf.md`](rf-rnf.md) quedan cubiertos por cada historia. Es cobertura, no
descomposición: una HU no "genera" los RF, los **realiza**.

| HU | RF relacionados | Condiciones de satisfacción (resumen — ver backlog) |
|---|---|---|
| HU-01 | RF-01, RF-02, RF-03, RF-04 | Login correcto → sesión + rol; credenciales malas o cuenta deshabilitada → rechazo; cada rol llega a su pantalla |
| HU-02 | RF-05, RF-06, RF-07 | Supervisor crea Técnico (nombre, apellidos, usuario, grupo, profesión; contraseña por defecto a cambiar; activo); usuario duplicado → rechazo |
| HU-03 | RF-08, RF-09 | Deshabilitar Técnico propio; la cuenta deshabilitada pierde el acceso aunque tenga sesión |
| HU-04 | RF-11, RF-12, RF-13 | Registrar ubicación técnica (4 niveles); combinación repetida → rechazo; listar |
| HU-05 | RF-14, RF-15, RF-16, RF-20 | Crear OT con descripción y pasos; el sistema genera 3 pasos de seguridad; estado inicial "asignada" |
| HU-06 | RF-17, RF-18 | Sin paso PM01 → rechazo; PM01 con horas planificadas ≤ 0 → rechazo |
| HU-07 | RF-21 | El Técnico ve solo las OTs asignadas a él; sin OTs → lista vacía |
| HU-08 | RF-22, RF-23, RF-24 | Detalle con pasos y estados; la primera apertura pasa la OT a "en progreso"; OT ajena → rechazo |
| HU-09 | RF-19, RF-25, RF-26, RF-27, RF-28 | Cierre PM01 (duración, descripción, resultado, estado); se registra la hora y se señala si es fuera del horario del grupo; recierre → rechazo; Supervisor no cierra; todos los PM01 cerrados → OT "cerrada" |
| HU-10 | RF-29 | El Supervisor ve el avance (asignada / en progreso / cerrada) de cada OT de su grupo |
| HU-11 | RF-30, RF-31, RF-32, RF-33 | Texto libre → secciones estándar; números intactos; sin diagnósticos añadidos |
| HU-12 | RF-34, RF-35 | El texto estandarizado es editable; el cierre guarda el texto confirmado |
| HU-13 | RF-36 | LLM sin respuesta / caído / sin conexión → se continúa con el texto original |
| HU-14 | RF-37, RF-38 | Cierre guardado en el dispositivo sin conexión y persistente; paso marcado como pendiente |
| HU-15 | RF-39, RF-40, RF-41 | Al reconectar se envían los pendientes; aceptados salen de la cola, rechazados quedan para reintento; contador visible |
| HU-16 | RF-42 | (futuro) |
| HU-17 | RF-43 | (futuro) |
| HU-18 | RF-44 | (futuro) |
| HU-20 | RF-49, RF-50 | Enviar comunicado (texto y/o imagen) a técnico o grupo; comunicado vacío → rechazo |
| HU-21 | RF-51, RF-52, RF-53 | Ver comunicados vigentes; los expirados dejan de mostrarse y su imagen se elimina |
| HU-22 | RF-45, RF-46 | Importar técnicos y ubicaciones desde Excel; validación por fila y reporte de errores |
| HU-23 | RF-47 | Exportar el listado de OTs (con filtros) a Excel/CSV |
| HU-24 | RF-48 | Exportar el reporte de cierres de un periodo a Excel/CSV |
| *(transversal)* | RF-10 | "Restringir según el rol y rechazar accesos indebidos": aplica a HU-01 y a toda historia que exponga una operación |

### Análisis de brechas

Con el catálogo actual de `rf-rnf.md` la cobertura es **completa**: RF-01 a RF-53 quedan
cubiertos por alguna HU. Repetir este análisis **después de conciliar `rf-rnf.md` con el
informe aprobado**; para cada RF nuevo sin HU decidir: nueva historia, criterio de una
existente, o fuera del alcance de la entrega (E5 / E6 / futuro).

---

## 5. Los RNF y las historias

El texto de cada RNF está en [`rf-rnf.md`](rf-rnf.md). Aquí, cómo se aplica cada uno al
trabajo de las historias.

| RNF | Cómo se realiza en el proyecto |
|---|---|
| RNF-01 · RNF-02 · RNF-03 · RNF-04 (Seguridad) | Definition of Done → "RNF transversales / Seguridad"; condición transversal en toda historia que exponga una operación. |
| RNF-05 (Autorización) | Definition of Done → "RNF transversales / Autorización"; condiciones de error de rol en HU-05, HU-08, HU-09. |
| RNF-06 (Rendimiento — tiempo de respuesta) | **Tarjeta de restricción** en el Product Backlog (etiqueta `restricción`, sin puntos) + condición transversal en los endpoints. |
| RNF-07 (Rendimiento — timeout del LLM) | Cubierto por HU-13 (degradación al texto original) + Definition of Done → "Tiempo de respuesta". |
| RNF-08 (Disponibilidad) | Definition of Done → "App móvil" y "RNF transversales / Resiliencia". |
| RNF-09 (Operación sin conexión) | Definition of Done → "RNF transversales / Operación sin conexión"; historias HU-14 y HU-15. |
| RNF-10 (Usabilidad) | Definition of Done → "Común" (mensajes de error claros); revisión en Sprint Review. |
| RNF-11 (Compatibilidad Android) | Definition of Done → "App móvil" (probado en dispositivo/emulador Android). |
| RNF-12 (Mantenibilidad) | Definition of Done → "Backend" (hexagonal) y "App móvil" (MVVM). |
| RNF-13 (Trazabilidad) | Cubierto por HU-09 (el cierre se guarda con fecha y hora); verificado en el detalle de la OT. |

**Reglas:**

- RNF **transversal** (seguridad, autorización, resiliencia, offline) → Definition of Done + condición transversal en cada historia afectada. No genera trabajo aparte.
- RNF **medible con verificación propia** (tiempo de respuesta, capacidad) → **tarjeta de restricción** en `📋 Product Backlog` (etiqueta `restricción`, sin puntos), con su criterio de verificación. Se revisa en la Sprint Review.
- Todos conservan su identificador `RNF-0X` para la trazabilidad con el informe.

---

## 6. Qué va al cuerpo del informe y qué al anexo

| Al cuerpo (Capítulo de análisis / metodología) | Al **Anexo** |
|---|---|
| Qué es una historia de usuario y su relación con RF/RNF (secciones 1 y 2) | Catálogo completo de RF, exportado del tablero |
| Estructura de temas E1–E5 y tabla resumen (nº de RF/RNF por módulo) | Catálogo completo de RNF |
| 2–3 historias completas por tema con sus condiciones de satisfacción | Export del Product Backlog completo (tablero) |
| Matriz de cobertura Historia → RF (sección 4) y realización de RNF (sección 5) | Capturas del tablero Scrumban |

---

## 7. Proceso para ti (Sprint 0)

1. **Concilia** [`rf-rnf.md`](rf-rnf.md) con el catálogo de requerimientos de tu informe aprobado (ese informe manda: agrega, quita o renumera).
2. **Exporta** el catálogo conciliado a PDF/Excel → será el Anexo.
3. **Revisa la matriz de la sección 4**: ya está prellenada con el catálogo actual; ajústala tras la conciliación.
4. **Corre el análisis de brechas** de la sección 4 con los RF definitivos.
5. **Crea las tarjetas de restricción** en Trello para los RNF que las necesiten — hoy: RNF-06.
6. **Ajusta la Definition of Done** si algún RNF transversal no está reflejado ([definition-of-done.md](definition-of-done.md)).
7. **Actualiza** la tabla resumen (nº de RF/RNF por módulo) en el cuerpo del informe.
