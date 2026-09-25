# Atributos de calidad y escenarios (QAS) - insumo para la decisión de arquitectura

Este documento reúne la información que pide el proceso de selección de arquitectura:
contexto del sistema, atributos de calidad priorizados y los **Quality Attribute Scenarios (QAS)** en forma de seis partes. No decide la arquitectura: es la entrada para la evaluación multicriterio.

Fuentes internas: [`rf-rnf.md`](../scrum/rf-rnf.md), [`historias-usuario.md`](../scrum/historias-usuario.md),
[`discovery/vision-y-roles.md`](../scrum/discovery/vision-y-roles.md), esquema de base de datos.

## 1. Contexto del sistema (respuestas al cuestionario de decisión)

### 1.1 Dominio y contexto del problema
Sistema de gestión de **Órdenes de Trabajo (OT) de mantenimiento** para el Departamento de Mantenimiento (caso ESPODI). Propósito central: **realizar un registro y un cierre apropiado** de las OT por turno, **notificar** al técnico su asignación y **estandarizar** la descripción de la orden trabajo con un modelo de lenguaje.

Entorno de operación:
- **Supervisores:** oficina de turno, con conexión estable; equipo de escritorio o móvil.
- **Técnicos:** planta industrial, en movimiento, con **conectividad de datos intermitente o nula**; exclusivamente móvil (Android).
- **Administrador:** oficina, con conexión; uso esporádico.
- Operación en **3 turnos** que cubren 24 h.

### 1.2 Atributos de calidad prioritarios

| Prioridad | Atributo | Por qué |
|---|---|---|
| **1 (crítico)** | **Disponibilidad / tolerancia a fallos de red** (operación offline con sincronización) | El técnico registra el trabajo en zonas sin señal; perder un cierre es perder la evidencia que el sistema existe para asegurar. |
| **2 (crítico)** | **Mantenibilidad / modificabilidad** | Un solo desarrollador; el sistema seguirá creciendo (módulo de comunicados, analítica); el componente LLM debe poder cambiarse de proveedor; el tribunal evalúa la calidad estructural. |
| **3 (crítico)** | **Integridad / consistencia de datos** | El objetivo del producto es un registro fiable; la sincronización offline introduce riesgo de duplicados y estados inconsistentes (doble cierre, transición de estado de OT). |
| Secundario | Seguridad | Necesaria pero resuelta con mecanismos estándar (hash de contraseña, sesión con expiración, autorización por rol); no fuerza decisiones estructurales grandes. |
| Secundario | Rendimiento / latencia | Cargas bajas; basta percentil 95 ≤ 2 s en la API y ≤ 8 s en el LLM con degradación. |
| Secundario | Usabilidad | Atributo de interfaz, no de arquitectura. |
| Secundario | Portabilidad / compatibilidad | Android; el framework de UI ya lo cubre. |
| **No es driver** | Escalabilidad / alto throughput / tiempo real estricto | Dominio de una planta: decenas de usuarios, cientos de OT al mes. No hay caso de crecimiento explosivo ni de baja latencia dura. |

### 1.3 Restricciones del equipo y del proyecto
- **Equipo:** 1 desarrollador.
- **Tiempo:** proyecto de grado con fecha de entrega próxima; se reinició el desarrollo por cambio de metodología.
- **Metodología:** Scrum + Kanban (Scrumban), ya definida.
- **Base de datos:** BD relacional PostgreSQL ya diseñado (10 tablas) a partir de la lógica de negocio.

### 1.4 Integraciones y volumen técnico
- **Única integración externa obligatoria:** API de un LLM (OpenAI, `gpt-4o-mini`) para estandarización de descripciones, consumida mediante un adaptador y degradación al texto original.
- **Notificaciones push** al técnico (asignación de OT): proveedor por definir (p. ej. FCM).
- **Almacenamiento de imágenes** para el módulo de Comunicados (imágenes con fecha de expiración): por definir (almacenamiento de objetos o el propio servidor).
- **Base de datos:** PostgreSQL. Volumen estimado: ~decenas de usuarios, ~decenas de técnicos por turno, cientos de OT/mes.
- **Autenticación:** **propia** — sesión firmada (JWT) + `password_hash` bcrypt. `auth_user_id` del esquema queda reservado, sin uso, para un posible SSO futuro (ver [`../conciliacion.md`](../conciliacion.md) D-09).

### 1.5 Estrategia de infraestructura y despliegue
- Preferencia por **PaaS simple** (tipo Railway/Render) para el backend + PostgreSQL gestionado. Sin Kubernetes, sin orquestación de contenedores compleja.
- Cliente móvil distribuido como **APK** (Flutter).
- Sin requisito de multi-región ni de alta disponibilidad con redundancia.

### 1.6 Decisión a tomar en dos planos
1. **Estilo de despliegue** (cómo se distribuye físicamente): monolito · monolito modular · basado en servicios · microservicios.
2. **Estilo estructural interno** (cómo se organiza el código): en capas · hexagonal (puertos y adaptadores) · Clean Architecture · MVC/MVVM en el cliente.

Los QAS del 3. alimentan ambas decisiones; la mayoría de los de disponibilidad e integridad pesan sobre el despliegue y el cliente, y los de mantenibilidad sobre la estructura interna.

---

## 2. Resumen de QAS

| QAS | Atributo | Escenario (resumen) | RNF |
|---|---|---|---|
| QAS-01 | Disponibilidad | Registrar un cierre sin conexión | RNF-09 |
| QAS-02 | Disponibilidad | Sincronización automática al reconectar | RNF-09 |
| QAS-03 | Disponibilidad | Consultar OTs con el backend caído/lento | RNF-08 |
| QAS-04 | Disponibilidad | Fallo del proveedor LLM | RNF-07 |
| QAS-05 | Mantenibilidad | Cambiar de proveedor LLM | RNF-12 |
| QAS-06 | Mantenibilidad | Añadir un módulo funcional nuevo | RNF-12 |
| QAS-07 | Mantenibilidad | Cambiar una regla de negocio (horario laboral del grupo) | RNF-12 |
| QAS-08 | Mantenibilidad | Probar la lógica de negocio sin infraestructura | RNF-12 |
| QAS-09 | Integridad | Reenvío duplicado de un cierre por reintento | RNF-13 |
| QAS-10 | Integridad | Rechazo atómico de una OT sin paso PM01 | - |
| QAS-11 | Integridad | Cierre concurrente del último paso de una OT | RNF-13 |
| QAS-12 | Seguridad | Acceso a una OT ajena | RNF-05 |
| QAS-13 | Seguridad | Contraseñas y tokens en reposo y en tránsito | RNF-01, RNF-03 |
| QAS-14 | Rendimiento | Latencia de las operaciones habituales | RNF-06 |
| QAS-15 | Rendimiento | Latencia de la estandarización con LLM | RNF-07 |
| QAS-16 | Escalabilidad | Crecimiento del volumen (horizonte 2–3 años) | - |

---

## 3. Catálogo de QAS (forma de seis partes)

**Fuente** - **Estímulo** - **Artefacto** - **Entorno** - **Respuesta** - **Medida de respuesta**

### Disponibilidad / tolerancia a fallos de red

**QAS-01 - Registrar un cierre sin conexión**
- **Fuente:** Técnico en planta.
- **Estímulo:** confirma el cierre de un paso PM01.
- **Artefacto:** app móvil (módulo de cierres) y su almacenamiento local.
- **Entorno:** sin conectividad de datos.
- **Respuesta:** la app persiste el cierre en el almacenamiento local, confirma al usuario y marca el paso como "pendiente de sincronización".
- **Medida:** el 100 % de los cierres registrados sin conexión se conservan; 0 pérdidas tras cerrar y reabrir la app; confirmación al usuario en < 1 s.

**QAS-02 - Sincronización automática al reconectar**
- **Fuente:** el sistema operativo del dispositivo (evento de conectividad).
- **Estímulo:** se restablece la conexión de datos.
- **Artefacto:** servicio de sincronización del cliente + API de cierres.
- **Entorno:** hay N cierres en la cola local.
- **Respuesta:** el servicio envía cada cierre pendiente; los aceptados se eliminan de la cola; los rechazados quedan marcados para reintento manual y no bloquean a los demás.
- **Medida:** el 100 % de los cierres válidos en cola llegan al servidor dentro de los 60 s siguientes a recuperar la conexión; un fallo individual no impide sincronizar el resto.

**QAS-03 - Consultar OTs con el backend caído o lento**
- **Fuente:** Técnico.
- **Estímulo:** abre la lista de OTs de su turno.
- **Artefacto:** app móvil + caché local de OTs.
- **Entorno:** el backend no responde o tarda más de 10 s.
- **Respuesta:** la app muestra los datos de la última sincronización disponible con un indicador de "sin conexión" y permite seguir trabajando (abrir detalle, redactar cierres).
- **Medida:** la app nunca queda bloqueada; muestra contenido cacheado en < 2 s; ninguna funcionalidad de campo depende de una respuesta en vivo salvo la estandarización.

**QAS-04 - Fallo del proveedor LLM**
- **Fuente:** servicio externo (API del LLM).
- **Estímulo:** responde con error o supera los 8 s.
- **Artefacto:** adaptador de estandarización en el backend.
- **Entorno:** operación normal, con conexión.
- **Respuesta:** el backend responde con un código de "servicio no disponible"; la app ofrece continuar con el texto original y el cierre no se bloquea.
- **Medida:** el flujo de cierre se completa sin estandarización en el 100 % de los casos de fallo del LLM; ningún reintento supera los 8 s.

### Mantenibilidad / modificabilidad

**QAS-05 - Cambiar de proveedor LLM**
- **Fuente:** desarrollador.
- **Estímulo:** se decide sustituir OpenAI por otro proveedor de estandarización.
- **Artefacto:** adaptador de salida del LLM.
- **Entorno:** mantenimiento, diseño en tiempo.
- **Respuesta:** se implementa un adaptador nuevo que cumple el mismo contrato (puerto); no cambian el dominio, los casos de uso ni la API pública.
- **Medida:** el cambio afecta a ≤ 1 módulo nuevo y 0 líneas de la lógica de dominio; esfuerzo estimado ≤ 1 día.

**QAS-06 - Añadir un módulo funcional nuevo**
- **Fuente:** cliente (Mantenimiento).
- **Estímulo:** se pide un módulo nuevo, no previsto en los sprints actuales (por ejemplo, la analítica agregada del tema E5: dashboards de carga por técnico).
- **Artefacto:** backend y app.
- **Entorno:** diseño en tiempo.
- **Respuesta:** el módulo se agrega como una rebanada nueva en `funcionalidades/` (dominio, puerto, caso de uso, adaptador, endpoint / pantalla) sin modificar los módulos existentes.
- **Medida:** 0 cambios en el código de los módulos existentes; el módulo nuevo se prueba de forma aislada.

**QAS-07 - Cambiar una regla de negocio**
- **Fuente:** cliente (Mantenimiento).
- **Estímulo:** cambia el horario laboral de un grupo o la regla de "registro fuera de horario".
- **Artefacto:** lógica de dominio (cálculo de turno).
- **Entorno:** mantenimiento.
- **Respuesta:** el cambio se localiza en la capa de dominio, sin tocar adaptadores, base de datos ni UI.
- **Medida:** el cambio se concentra en 1 función; queda cubierto por pruebas unitarias que no requieren base de datos ni red.

**QAS-08 - Probar la lógica de negocio sin infraestructura**
- **Fuente:** desarrollador.
- **Estímulo:** ejecuta la suite de pruebas de reglas de negocio.
- **Artefacto:** casos de uso + dominio.
- **Entorno:** integración continua o local.
- **Respuesta:** las pruebas corren con dobles de prueba de los puertos, sin base de datos real, sin red y sin el LLM real.
- **Medida:** las reglas críticas (paso PM01 obligatorio, transición de estado de la OT, no duplicar cierres) están cubiertas por pruebas que corren en < 10 s.

### Integridad / consistencia de datos

**QAS-09 - Reenvío duplicado de un cierre**
- **Fuente:** servicio de sincronización del cliente.
- **Estímulo:** reenvía un cierre que ya había llegado al servidor (se perdió la respuesta anterior).
- **Artefacto:** endpoint de cierre + base de datos.
- **Entorno:** reconexión tras un corte intermitente.
- **Respuesta:** el servidor reconoce el duplicado (identificador idempotente generado en el cliente o restricción de unicidad) y no crea un segundo registro.
- **Medida:** 0 cierres duplicados en la base de datos ante N reenvíos del mismo cierre.

**QAS-10 - Rechazo atómico de una OT inválida**
- **Fuente:** Supervisor.
- **Estímulo:** envía una OT cuya lista de pasos no incluye ningún PM01.
- **Artefacto:** caso de uso de creación de OT + transacción de base de datos.
- **Entorno:** operación normal.
- **Respuesta:** la operación se rechaza con un error de validación de negocio y no se persiste ninguna fila (OT ni pasos).
- **Medida:** 0 OT sin PM01 en la base de datos; la validación ocurre en el dominio, no solo en la interfaz.

**QAS-11 - Cierre concurrente del último paso**
- **Fuente:** dos peticiones casi simultáneas.
- **Estímulo:** llegan dos cierres para el último paso PM01 de la misma OT.
- **Artefacto:** caso de uso de cierre + base de datos.
- **Entorno:** carga normal.
- **Respuesta:** solo una prospera; la otra recibe "el paso ya fue cerrado"; la transición de la OT a "cerrada" ocurre una sola vez.
- **Medida:** 0 estados inconsistentes; garantizado por transacción y restricción de unicidad a nivel de base de datos.

### Seguridad

**QAS-12 - Acceso a una OT ajena**
- **Fuente:** Técnico autenticado.
- **Estímulo:** solicita el detalle de una OT que no le fue asignada.
- **Artefacto:** endpoint de OT.
- **Entorno:** operación normal.
- **Respuesta:** el sistema deniega con "acceso no autorizado" y registra el intento.
- **Medida:** el 100 % de los accesos fuera de rol o de propiedad se deniegan; verificado con pruebas de acceso cruzado entre roles.

**QAS-13 - Credenciales en reposo y en tránsito**
- **Fuente:** atacante con acceso a la base de datos o a la red.
- **Estímulo:** intenta obtener contraseñas o suplantar una sesión.
- **Artefacto:** almacenamiento de usuarios y canal de transporte.
- **Entorno:** operación normal.
- **Respuesta:** las contraseñas están con hash (bcrypt); el transporte usa HTTPS; los tokens de sesión expiran.
- **Medida:** 0 contraseñas en texto legible; tokens válidos ≤ 24 h; ningún endpoint sensible accesible sin sesión válida.

### Rendimiento

**QAS-14 - Latencia de las operaciones habituales**
- **Fuente:** usuario (Supervisor o Técnico).
- **Estímulo:** crea una OT, lista sus OTs o registra un cierre.
- **Artefacto:** API del backend.
- **Entorno:** carga normal (≤ ~50 usuarios concurrentes por turno; ~cientos de OT/mes).
- **Respuesta:** la operación se completa correctamente.
- **Medida:** percentil 95 ≤ 2 s, excluida la llamada al LLM.

**QAS-15 - Latencia de la estandarización con LLM**
- **Fuente:** Técnico.
- **Estímulo:** solicita estandarizar una descripción.
- **Artefacto:** adaptador del LLM.
- **Entorno:** operación normal.
- **Respuesta:** devuelve el texto estandarizado o degrada al original.
- **Medida:** respuesta útil en ≤ 8 s en el 95 % de los casos; si se supera, degradación inmediata.

### Escalabilidad (no es driver - se documenta para justificar que no lo es)

**QAS-16 - Crecimiento del volumen**
- **Fuente:** crecimiento del negocio.
- **Estímulo:** se duplican los técnicos y las OT respecto al volumen actual.
- **Artefacto:** sistema completo.
- **Entorno:** horizonte de 2–3 años.
- **Respuesta:** el sistema sostiene la carga añadiendo recursos a un único despliegue (escalado vertical), sin rediseño ni partición.
- **Medida:** no se requiere escalado horizontal ni particionado en el horizonte previsto → la escalabilidad **no condiciona** la elección de arquitectura.

---

## 4. Notas para la evaluación

1. **Escenarios de disponibilidad e integridad → pesan sobre despliegue y cliente.**
   QAS-01/02/03/09/11 empujan hacia un cliente con base de datos local y cola de sincronización idempotente, y hacia un backend con transacciones y restricciones de unicidad, con independencia del estilo de despliegue. No exigen microservicios.
2. **Escenarios de mantenibilidad → pesan sobre la estructura interna.**
   QAS-05/06/07/08 favorecen una separación explícita entre dominio y adaptadores (hexagonal o Clean) en el backend y MVVM en el cliente. El costo es más ceremonia inicial (más carpetas y contratos); el beneficio es aislar el LLM y probar sin infraestructura.
3. **La escalabilidad no es driver** (QAS-16). Un monolito o monolito modular cubre
   los QAS con la menor complejidad operativa, que es una restricción dura del proyecto (§1.3). Microservicios añadirían costo de infraestructura, despliegue y pruebas sin ningún QAS que lo justifique.
4. **Prototipos de riesgo sugeridos** (paso 5 del método): (a) cola de sincronización
   offline con reintentos e idempotencia end-to-end; (b) adaptador del LLM con timeout y degradación; (c) transacción de cierre con control de concurrencia. Son los puntos con más incertidumbre técnica.
5. **Divergencias entre el esquema de base de datos y los requisitos** (estados de la OT,
   número de turno, primera visualización, pasos fijos, campos del cierre, autenticación,
   módulo Comunicados): están inventariadas y en proceso de resolución en
   [`../conciliacion.md`](../conciliacion.md). Resolverlas es requisito para que los QAS de
   integridad (QAS-09, QAS-10, QAS-11) y de seguridad (QAS-13) sean verificables.
