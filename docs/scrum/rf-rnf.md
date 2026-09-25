# Requerimientos funcionales (RF) y no funcionales (RNF)

Un RF describe una capacidad del sistema. Una historia de usuario (HU) es la forma en que el equipo planifica el trabajo; una HU puede cubrir varios RF.

---

Aquí se lista lo que el sistema **debe hacer** (RF) y las **condiciones de calidad** que debe cumplir (RNF).

Esto se derivó del alcance acordado (visión del producto, roles de usuario, Product Backlog), del comportamiento del sistema de referencia y del **esquema de base de datos**. Las divergencias resueltas están en [`../conciliacion.md`](../conciliacion.md).

---

## Requerimientos funcionales (RF)
Estructura: Código y Requerimiento

### Acceso y roles

RF-01: El sistema debe permitir iniciar sesión con nombre de usuario y contraseña.
RF-02: El sistema debe rechazar el inicio de sesión cuando las credenciales son incorrectas o la cuenta está deshabilitada, sin indicar cuál de los dos datos falló.
RF-03: El sistema debe entregar, al iniciar sesión, una sesión de acceso y el rol del usuario, deducido de su pertenencia a Supervisores o a Técnicos.
RF-04: El sistema debe llevar a cada usuario a la pantalla inicial que corresponde a su rol (Administrador, Supervisor o Técnico).
RF-05: El sistema debe permitir al Supervisor registrar cuentas de Técnico indicando nombre, apellidos, nombre de usuario, grupo y profesión (eléctrico, mecánico o electromecánico).
RF-06: El sistema debe asignar a cada Técnico nuevo una contraseña inicial por defecto y el estado "activo", y exigir el cambio de esa contraseña en el primer inicio de sesión.
RF-07: El sistema debe impedir crear dos cuentas con el mismo nombre de usuario.
RF-08: El sistema debe permitir al Supervisor deshabilitar la cuenta de un Técnico que él registró.
RF-09: El sistema debe impedir el acceso de una cuenta deshabilitada, incluso si tenía una sesión abierta.
RF-10: El sistema debe restringir cada operación según el rol del usuario y rechazar los accesos que no correspondan a ese rol.

### Gestión de Órdenes de Trabajo

RF-11: El sistema debe permitir al Supervisor registrar ubicaciones técnicas con sector, subsector, sistema y subsistema.
RF-12: El sistema debe impedir registrar una ubicación técnica repetida (misma combinación de sector, subsector, sistema y subsistema).
RF-13: El sistema debe permitir consultar la lista de ubicaciones técnicas registradas.
RF-14: El sistema debe permitir al Supervisor crear una Orden de Trabajo indicando tipo de orden, ubicación técnica, técnico asignado, descripción, estado de la instalación (en marcha o detenida), fechas planificadas de inicio y fin, y prioridad (1 a 4).
RF-15: El sistema debe permitir definir los pasos de la Orden de Trabajo, cada uno con su descripción y su clave de control (PM01 o PMNN).
RF-16: El sistema debe generar automáticamente tres pasos de seguridad en cada Orden de Trabajo.
RF-17: El sistema debe exigir al menos un paso con clave de control PM01 en cada Orden de Trabajo.
RF-18: El sistema debe exigir un número de horas planificadas mayor que cero en cada paso PM01.
RF-19: El sistema debe registrar la hora de cada cierre de paso y señalar los que el Técnico realiza fuera del horario laboral de su grupo; el registro no se bloquea.
RF-20: El sistema debe registrar toda Orden de Trabajo nueva con estado "asignada".
RF-21: El sistema debe permitir al Técnico consultar únicamente las Órdenes de Trabajo asignadas a él.
RF-22: El sistema debe permitir consultar el detalle de una Orden de Trabajo con todos sus pasos y el estado de cada uno.
RF-23: El sistema debe cambiar la Orden de Trabajo al estado "en progreso" la primera vez que el Técnico asignado abre su detalle.
RF-24: El sistema debe impedir que un Técnico consulte o modifique Órdenes de Trabajo que no le fueron asignadas.
RF-25: El sistema debe permitir al Técnico registrar el cierre de un paso PM01 indicando duración real trabajada, descripción del trabajo realizado, resultado (ejecutado o no ejecutado), si el trabajo quedó finalizado y si no se realizó trabajo.
RF-26: El sistema debe impedir registrar dos veces el cierre de un mismo paso.
RF-27: El sistema debe cambiar la Orden de Trabajo al estado "cerrada" cuando todos sus pasos PM01 quedan cerrados.
RF-28: El sistema debe impedir que un Supervisor registre cierres de pasos.
RF-29: El sistema debe permitir al Supervisor consultar las Órdenes de Trabajo de su grupo con su estado (asignada, en progreso, cerrada).

### Estandarización de descripciones

RF-30: El sistema debe permitir al Técnico enviar una descripción de trabajo en texto libre para estandarizarla.
RF-31: El sistema debe devolver la descripción reorganizada en secciones estándar: equipo intervenido, actividades realizadas, mediciones termográficas, mediciones de vibración y observaciones.
RF-32: El sistema debe conservar sin cambios los valores numéricos de la descripción original.
RF-33: El sistema no debe agregar diagnósticos, conclusiones ni recomendaciones que el Técnico no haya escrito.
RF-34: El sistema debe permitir al Técnico revisar y editar la descripción estandarizada antes de enviarla con el cierre.
RF-35: El sistema debe guardar en el cierre el texto que el Técnico confirme, sea el estandarizado, el editado o el original.
RF-36: El sistema debe permitir continuar con la descripción original cuando el servicio de estandarización no responde, falla o no hay conexión.

### Operación sin conexión

RF-37: El sistema debe guardar en el dispositivo el cierre de un paso cuando no hay conexión, y conservarlo aunque se cierre la aplicación.
RF-38: El sistema debe señalar los pasos cuyo cierre está pendiente de sincronización.
RF-39: El sistema debe enviar automáticamente los cierres pendientes cuando se recupera la conexión.
RF-40: El sistema debe quitar de la cola local los cierres aceptados por el servidor y conservar los rechazados para volver a intentarlos.
RF-41: El sistema debe mostrar cuántos cierres están pendientes de sincronización.

### Administración y analítica (trabajo futuro)

RF-42: El sistema debe permitir al Administrador gestionar cuentas de Supervisor.
RF-43: El sistema debe ofrecer al Supervisor un panel de carga de trabajo por técnico.
RF-44: El sistema debe ofrecer un reporte de Órdenes de Trabajo por ubicación técnica.

### Importación y exportación

RF-45: El sistema debe permitir importar técnicos desde un archivo Excel, validando cada fila e informando de los errores.
RF-46: El sistema debe permitir importar ubicaciones técnicas desde un archivo Excel, validando cada fila e informando de los errores.
RF-47: El sistema debe permitir exportar el listado de Órdenes de Trabajo, con los filtros aplicados, a un archivo Excel o CSV.
RF-48: El sistema debe permitir exportar el reporte de cierres de paso de un periodo a un archivo Excel o CSV.

### Comunicados

RF-49: El sistema debe permitir al Supervisor enviar un comunicado, con texto y/o imagen, a un Técnico de su grupo o a todo su grupo.
RF-50: El sistema debe rechazar un comunicado que no contenga ni texto ni imagen.
RF-51: El sistema debe registrar cada comunicado con su fecha de envío y una fecha de expiración.
RF-52: El sistema debe dejar de mostrar los comunicados cuya fecha de expiración ya pasó.
RF-53: El sistema debe eliminar la imagen asociada a un comunicado una vez expirado.

---

## Requerimientos no funcionales (RNF)

RNF-01 (seguridad): Las contraseñas se guardan cifradas con un algoritmo de hash (bcrypt), nunca en texto legible.Revisión del código y de la base de datos.
RNF-02 (seguridad): Toda operación distinta del inicio de sesión exige una sesión de acceso válida.Una petición sin sesión válida es rechazada.
RNF-03 (seguridad): La sesión de acceso tiene una vigencia limitada (por defecto 24 horas).Una sesión vencida es rechazada.
RNF-04 (seguridad): Las claves y datos sensibles de configuración se leen de variables de entorno, no del código.Revisión del repositorio: no hay credenciales escritas en el código.
RNF-05 (Autorización): Cada operación comprueba el rol del usuario; un acceso que no corresponde a ese rol es rechazado.Pruebas de acceso cruzado entre roles.
RNF-06 (Rendimiento): Las respuestas del servidor, salvo la estandarización con IA, se entregan dentro del límite definido (referencia: 2 segundos) en condiciones normales.Medición de tiempos de respuesta.
RNF-07 (Rendimiento): La estandarización con IA espera como máximo 8 segundos; si se supera, el sistema continúa con el texto original.Prueba con el servicio lento o fuera de servicio.
RNF-08 (Disponibilidad): La aplicación móvil sigue siendo usable cuando el servidor responde con lentitud, mostrando un indicador de carga en cada operación.Prueba con el servidor ralentizado a propósito.
RNF-09 (Operación sin conexión): El registro del cierre de paso funciona sin conexión y se sincroniza solo al reconectar, sin pérdida de datos.Prueba en modo avión y posterior reconexión.
RNF-10 (Usabilidad): La interfaz está en español y muestra mensajes de error claros para el personal de mantenimiento.Revisión de pantallas y mensajes.
RNF-11 (Compatibilidad): La aplicación móvil funciona en dispositivos Android.Ejecución en un dispositivo o emulador Android.
RNF-12 (Mantenibilidad): El servidor separa la lógica de negocio de los detalles de framework y base de datos (arquitectura hexagonal + vertical slicing); la aplicación móvil separa la interfaz de la lógica (Clean Architecture + MVVM).Revisión de la estructura del código.
RNF-13 (Trazabilidad): Cada cierre de paso queda registrado con su fecha y hora.Consulta del detalle de la Orden de Trabajo después de un cierre.

## Resumen

Módulo y cantidad
1.- Acceso y roles; 10
2.- Gestión de OTs; 19
3.- Estandarización; 7
4.- Operación sin conexión; 5
5.- Administración y analítica (futuro); 3
6.- Importación y exportación; 4
7.- Comunicados; 5
**Total RF**
**53**
**Total RNF**
**13**
Transversales a todos los módulos
