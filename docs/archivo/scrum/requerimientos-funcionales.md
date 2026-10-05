# Requerimientos funcionales (versión resumida)

Vista consolidada de los requerimientos funcionales para el cuerpo del informe. Agrupa en
**21 RF** las 53 capacidades detalladas de [`rf-rnf.md`](rf-rnf.md), que se conserva como
catálogo detallado (anexo). La trazabilidad entre ambos está al final.

| Código | Módulo | Requerimiento |
|---|---|---|
| RF-01 | Autenticación y roles | El sistema debe permitir iniciar sesión con usuario y contraseña, y rechazar credenciales inválidas o cuentas deshabilitadas sin revelar cuál dato falló. |
| RF-02 | Autenticación y roles | El sistema debe controlar el acceso según el rol del usuario autenticado (Administrador, Supervisor, Técnico) y mostrar la pantalla inicial correspondiente a su rol. |
| RF-03 | Gestión de usuarios | El sistema debe permitir al Supervisor registrar, deshabilitar y consultar cuentas de Técnico de su grupo (nombre, apellidos, usuario, grupo y profesión), impidiendo nombres de usuario duplicados y exigiendo el cambio de la contraseña por defecto en el primer acceso. |
| RF-04 | Gestión de OTs | El sistema debe permitir registrar, consultar y evitar duplicados de ubicaciones técnicas (sector, subsector, sistema, subsistema). |
| RF-05 | Gestión de OTs | El sistema debe permitir al Supervisor crear Órdenes de Trabajo (tipo, ubicación técnica, técnico asignado, descripción, estado de la instalación, fechas planificadas y prioridad) con sus pasos, generando automáticamente tres pasos de seguridad y registrándolas con estado inicial "asignada". |
| RF-06 | Gestión de OTs | El sistema debe exigir en cada Orden de Trabajo al menos un paso PM01 con horas planificadas mayores que cero. |
| RF-07 | Gestión de OTs | El sistema debe permitir al Técnico consultar y ver el detalle únicamente de las Órdenes de Trabajo asignadas a él; la primera vez que abre el detalle, la Orden pasa al estado "en progreso". |
| RF-08 | Gestión de OTs | El sistema debe permitir al Técnico —y no al Supervisor— registrar el cierre de un paso PM01 (duración real, descripción, resultado y estado del trabajo), impidiendo el doble cierre; cuando todos los pasos PM01 quedan cerrados, la Orden pasa a "cerrada". |
| RF-09 | Gestión de OTs | El sistema debe registrar la hora de cada cierre y señalar los que el Técnico realiza fuera del horario laboral de su grupo, sin bloquearlos. |
| RF-10 | Gestión de OTs | El sistema debe permitir al Supervisor consultar las Órdenes de Trabajo de su grupo con su estado (asignada, en progreso, cerrada). |
| RF-11 | Estandarización con IA | El sistema debe estandarizar la descripción de trabajo en texto libre reorganizándola en secciones estándar (equipo, actividades, mediciones termográficas, mediciones de vibración y observaciones), sin alterar los valores numéricos ni añadir diagnósticos o conclusiones no escritos por el Técnico. |
| RF-12 | Estandarización con IA | El sistema debe permitir al Técnico revisar y editar la descripción estandarizada antes de enviarla, y guardar en el cierre el texto que confirme (estandarizado, editado u original). |
| RF-13 | Estandarización con IA | El sistema debe permitir continuar con la descripción original cuando el servicio de estandarización falla, se demora o no hay conexión, sin bloquear el cierre. |
| RF-14 | Operación sin conexión | El sistema debe guardar en el dispositivo los cierres registrados sin conexión, conservarlos aunque se cierre la aplicación y señalar los pasos pendientes de sincronización. |
| RF-15 | Operación sin conexión | El sistema debe sincronizar automáticamente los cierres pendientes al recuperar la conexión, retirando de la cola los aceptados, conservando los rechazados para reintento y mostrando la cantidad pendiente. |
| RF-16 | Importación y exportación | El sistema debe permitir importar técnicos y ubicaciones técnicas desde archivos Excel, validando cada fila e informando de los errores. |
| RF-17 | Importación y exportación | El sistema debe permitir exportar a Excel o CSV el listado de Órdenes de Trabajo (con los filtros aplicados) y el reporte de cierres de un periodo. |
| RF-18 | Comunicados | El sistema debe permitir al Supervisor enviar comunicados con texto y/o imagen a un Técnico o a todo su grupo, rechazar los que no tengan contenido y registrar su fecha de envío y de expiración. |
| RF-19 | Comunicados | El sistema debe dejar de mostrar los comunicados vencidos y eliminar su imagen asociada. |
| RF-20 | Administración y analítica *(trabajo futuro)* | El sistema debe permitir al Administrador gestionar cuentas de Supervisor. |
| RF-21 | Administración y analítica *(trabajo futuro)* | El sistema debe ofrecer paneles y reportes analíticos: carga de trabajo por técnico y Órdenes de Trabajo por ubicación técnica. |

## Resumen por módulo

| Módulo | RF | Estado |
|---|---|---|
| Autenticación y roles | RF-01, RF-02 | En la entrega |
| Gestión de usuarios | RF-03 | En la entrega |
| Gestión de OTs | RF-04 … RF-10 | En la entrega |
| Estandarización con IA | RF-11, RF-12, RF-13 | En la entrega |
| Operación sin conexión | RF-14, RF-15 | En la entrega |
| Importación y exportación | RF-16, RF-17 | En la entrega |
| Comunicados | RF-18, RF-19 | En la entrega |
| Administración y analítica | RF-20, RF-21 | Trabajo futuro |
| **Total** | **21** | |

## Trazabilidad con el catálogo detallado (`rf-rnf.md`)

| RF (resumido) | RF detallados |
|---|---|
| RF-01 | RF-01, RF-02 |
| RF-02 | RF-04, RF-10 |
| RF-03 | RF-03, RF-05, RF-06, RF-07, RF-08, RF-09 |
| RF-04 | RF-11, RF-12, RF-13 |
| RF-05 | RF-14, RF-15, RF-16, RF-20 |
| RF-06 | RF-17, RF-18 |
| RF-07 | RF-21, RF-22, RF-23, RF-24 |
| RF-08 | RF-25, RF-26, RF-27, RF-28 |
| RF-09 | RF-19 |
| RF-10 | RF-29 |
| RF-11 | RF-30, RF-31, RF-32, RF-33 |
| RF-12 | RF-34, RF-35 |
| RF-13 | RF-36 |
| RF-14 | RF-37, RF-38 |
| RF-15 | RF-39, RF-40, RF-41 |
| RF-16 | RF-45, RF-46 |
| RF-17 | RF-47, RF-48 |
| RF-18 | RF-49, RF-50, RF-51 |
| RF-19 | RF-52, RF-53 |
| RF-20 | RF-42 |
| RF-21 | RF-43, RF-44 |

Cobertura: los 53 RF detallados quedan cubiertos por algún RF resumido.
