# Visión, condiciones de satisfacción del release y roles de usuario

Capa de descubrimiento previa al [Mapa de historias](user-story-map.md) y al
[Product Backlog](../product-backlog.md).

Fuentes: Cohn, *Succeeding with Agile* (visión del producto); Cohn, *Agile Estimating and
Planning* (condiciones de satisfacción del release); Cohn, *User Stories Applied*
(cap. "User Role Modeling", personas).

> ⚠️ **Verificar contra el informe aprobado.** La visión y las condiciones de satisfacción
> deben ser coherentes con tu *objetivo general* y tus *objetivos específicos* literales.
> Ajusta los valores de las métricas con el cliente/tutor antes del Capítulo 3.

---

## 1. Visión del producto

> Para el **personal de Mantenimiento del Departamento** que hoy registra las Órdenes de
> Trabajo de mantenimiento preventivo (PM01) en planillas dispersas y con descripciones
> heterogéneas, la **aplicación móvil con integración de un LLM** estandariza el registro
> de OTs, notifica al técnico su asignación y estandariza la descripción del
> trabajo en secciones comparables. A diferencia del proceso manual actual, garantiza que
> cada OT del turno quede registrada de forma uniforme y consultable, incluso sin
> conexión en campo.

(Formato "elevator statement" de Cohn: *para \<usuario\>, que \<necesidad\>, el
\<producto\> es un \<categoría\> que \<beneficio clave\>; a diferencia de \<alternativa
actual\>, \<diferenciador\>*.)

---

## 2. Condiciones de satisfacción del release

Criterios de éxito de alto nivel del release de esta entrega (fecha por confirmar). Son la referencia
contra la que se prioriza el Product Backlog.

| # | Condición de satisfacción | Indicador | Estado esperado |
|---|---|---|---|
| CS-1 | Toda OT del turno queda registrada en el sistema (no en planillas) | % de OT del turno con cierre registrado | ≥ 90 % |
| CS-2 | Las descripciones de trabajo quedan en formato estandarizado por secciones | % de cierres con descripción estandarizada | ≥ 95 % |
| CS-3 | El técnico se entera de su asignación sin esperar al cambio de turno | tiempo desde creación de OT hasta que el técnico la ve | minutos |
| CS-4 | No se pierden cierres por falta de señal en campo | nº de cierres perdidos por falta de conexión | 0 (cola local + sync) |
| CS-5 | El sistema respeta los roles: cada usuario solo hace lo de su rol | accesos indebidos rechazados | 100 % (403) |

> Los porcentajes son propuestas. Acordar valores reales con el supervisor de
> Mantenimiento y el tutor.

---

## 3. Modelado de roles de usuario

### Roles

| Rol | Descripción | Contexto de uso | Frecuencia | Competencia técnica |
|---|---|---|---|---|
| **Supervisor** | Planifica y asigna el trabajo del turno; da seguimiento. | Oficina de turno, computadora o móvil; con conexión. | Varias veces por turno. | Media: usa sistemas de planta a diario. |
| **Técnico** | Ejecuta el mantenimiento en campo y registra el cierre del paso. | Planta, en movimiento; **señal intermitente o nula**; móvil. | En cada OT ejecutada. | Baja–media: usa el móvil, poco software de escritorio. |
| **Administrador** *(rol futuro, fuera de esta entrega)* | Gestiona cuentas de Supervisor y consulta analítica agregada. | Oficina; con conexión. | Esporádica. | Media–alta. |

> El rol se **deriva** de la pertenencia a las tablas `Supervisores` o `Tecnicos` de la base de datos; un usuario sin pertenencia a ninguna es Administrador (rol futuro). No hay columna `rol` explícita.

### Atributos de rol relevantes para el diseño

- El **Técnico** es el rol más restringido y el más expuesto a fallos de red → justifica
  la operación sin conexión (E4) y los estados de carga/errores explícitos (RNF de la DoD).
- El **Supervisor** necesita vistas de conjunto por turno → justifica la lista de OTs del
  turno y el indicador de avance (E2, HU-07, HU-10).
- El **Administrador** no participa del flujo núcleo → sus historias quedan en E5 (futuro).

### Personas (una por rol activo)

**Marcelo — Supervisor de turno.** 42 años. Coordina 6–10 técnicos por turno. Hoy arma
las OTs en una planilla y las comunica de palabra o en papel al inicio del turno. Le
molesta descubrir a mitad de turno que una OT no se ejecutó porque "no le llegó" al
técnico. Quiere crear la OT una vez, bien, y ver quién la vio y quién la cerró.

**Rosa — Técnica mecánica.** 35 años. Trabaja en planta con el celular en el bolsillo,
guantes, y zonas donde no hay señal. Hoy anota mediciones en una libreta y las pasa a
limpio al final del turno; a veces se pierden o quedan ilegibles. Quiere registrar el
cierre en el momento, aunque no tenga señal, y que el texto quede "presentable" sin tener
que redactarlo dos veces.

---

## 4. De los roles y sus metas a los temas del backlog

Agrupar las metas de cada rol por el objetivo que sirven produce los temas E1–E7.
(La secuencia narrativa de estas metas es la espina dorsal del [mapa de historias](user-story-map.md).)

| Rol | Meta | Tema |
|---|---|---|
| Todos | Entrar al sistema con mi rol | **E1 · Acceso y roles** |
| Supervisor | Tener el catálogo de ubicaciones y las cuentas de mis técnicos | **E1 · Acceso y roles** |
| Supervisor | Crear y asignar la OT del turno de forma uniforme | **E2 · Gestión de OTs** |
| Supervisor | Ver el avance de las OTs del turno | **E2 · Gestión de OTs** |
| Técnico | Consultar mis OTs del turno desde el campo | **E2 · Gestión de OTs** |
| Técnico | Registrar el cierre del paso donde ejecuto | **E2 · Gestión de OTs** |
| Técnico | Que mi descripción quede en formato comparable | **E3 · Estandarización con LLM** |
| Técnico | No perder el registro cuando no hay señal | **E4 · Operación sin conexión** |
| Administrador | Gestionar Supervisores y ver analítica agregada | **E5 · Administración y analítica (futuro)** |
| Supervisor | Enviar comunicados a su grupo | **E6 · Comunicados** |
| Administrador | Cargar el catálogo desde Excel y exportar reportes | **E7 · Importación y exportación** |

### Justificación del recorte de alcance

Las metas del Administrador y la analítica agregada (dashboards de carga, reportes por
ubicación, horas por técnico) no forman parte del flujo núcleo de ningún rol operativo
del turno. Se registran como tema **E5** y quedan fuera del release de esta entrega por la
restricción de tiempo del reinicio de metodología. El seguimiento "en vivo" que necesita
el Supervisor se cubre parcialmente con el indicador de avance de la OT (HU-10).
