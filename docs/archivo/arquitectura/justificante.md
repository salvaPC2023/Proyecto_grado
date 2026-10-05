# Justificación de la arquitectura

El documento [`quality-attributes.md`](quality-attributes.md) proporciona la información de entrada necesaria para justificar las decisiones de arquitectura del proyecto de grado. A partir de los Quality Attribute Scenarios (QAs) y el contexto operativo de la planta industrial (caso ESPODI), el análisis se estructura en los dos planos arquitectónicos fundamentales: el **estilo de despliegue** y la **estructura interna** (backend y frontend).

Al final hay un **glosario** con los términos que puedan no entenderse.

## 1. Estilo de despliegue: Monolito Modular

**Factores determinantes.** La escalabilidad masiva no es un *driver* de arquitectura, ya que el sistema operará con decenas de usuarios por turno y cientos de OTs al mes.

**Decisión y justificación.** Un monolito o monolito modular alojado en una plataforma PaaS simple (como Railway o Render) con PostgreSQL gestionado satisface todos los requisitos operativos. Elegir microservicios aumentaría la complejidad de infraestructura, despliegue y pruebas sin que ningún QAs lo demande.

## 2. Estructura interna del backend: Arquitectura Hexagonal

**Factores determinantes.** Mantenibilidad / modificabilidad (desarrollador único, evolución del sistema y aislamiento de la API de LLM) e integridad de datos.

**Decisión y justificación.** La arquitectura hexagonal (puertos y adaptadores) separa las reglas de negocio (dominio) de la infraestructura externa. Esto garantiza que cambiar de proveedor de LLM solo afecte a un adaptador de salida sin modificar la lógica central (QAs-05) y permite probar las reglas de negocio de forma aislada sin necesidad de base de datos ni red (QAs-08).

**Organización del código.** Sobre la arquitectura hexagonal se aplica *vertical slicing*: el código se agrupa por funcionalidad y no por capa técnica. Cada funcionalidad contiene su propio dominio, puertos y adaptadores. El criterio es el mismo usado en un proyecto anterior de la materia Taller de Software.

## 3. Estructura interna del frontend: Clean Architecture + MVVM (Offline-First)

**Factores determinantes.** Disponibilidad / tolerancia a fallos de red (operación técnica
en zonas de planta sin conectividad).

**Decisión y justificación.** La organización del cliente móvil (Flutter) mediante Clean Architecture y MVVM, integrada con una base de datos local y una cola de sincronización, permite almacenar cierres de OT localmente en menos de 1 s (QAs-01) y transmitirlos automáticamente al detectar red de forma transparente (QAs-02).

## 4. Mecanismos clave e incertidumbres a mitigar

- **Idempotencia en sincronización.** Para prevenir registros duplicados cuando se
  reintentan envíos tras fallos de red, el servidor debe validar identificadores de
  transacción idempotentes generados por el cliente (QAs-09).

- **Degradación tolerante del LLM.** Si la API del LLM tarda más de 8 segundos o falla, el backend debe degradar la respuesta al texto original sin detener la transacción del cierre de la OT (QAs-04).

- **Alineación previa a la programación.** Existe una divergencia detectada entre el catálogo de requisitos funcionales y el esquema de base de datos (relacionada con estados de la OT y columnas faltantes), la cual debe conciliarse antes de programar para asegurar
  los escenarios de integridad. El inventario completo y su resolución están en [`../conciliacion.md`](../conciliacion.md).

## 5. Glosario

| Término | En palabras simples |
|---|---|
| **QAs (Quality Attribute Scenario)** | Descripción concreta de cómo debe responder el sistema ante una situación, con una medida (tiempo, porcentaje) que permite comprobarlo. |
| **Driver de arquitectura** | Un factor que realmente condiciona la decisión de arquitectura. |
| **Monolito** | Una sola aplicación que se despliega de una vez. |
| **Monolito modular** | Un monolito dividido por dentro en módulos bien separados. |
| **Microservicios** | Muchas aplicaciones pequeñas e independientes que se despliegan y mantienen por separado. |
| **PaaS** | Servicio de alojamiento que ejecuta la aplicación sin que haya que administrar servidores. |
| **PostgreSQL gestionado** | Base de datos PostgreSQL operada por la propia plataforma (copias de seguridad, actualizaciones, disponibilidad). |
| **Arquitectura hexagonal (puertos y adaptadores)** | Las reglas de negocio en el centro, sin depender de nada externo; la base de datos, el LLM y la web se conectan mediante contratos. |
| **Dominio** | Las reglas de negocio del sistema (qué es una OT, cuándo se cierra, qué se valida). |
| **Puerto** | Un contrato que dice *qué* se necesita, sin decir con qué tecnología. |
| **Adaptador** | La implementación concreta de un puerto con una tecnología específica (PostgreSQL, OpenAI, HTTP). |
| **Adaptador de salida** | Adaptador que conecta el dominio con un servicio externo (por ejemplo, la API del LLM). |
| **Vertical slicing** | Organizar el código por funcionalidad completa en lugar de por capa técnica. |
| **Clean Architecture** | Estilo de capas: el dominio en el centro, la infraestructura afuera. |
| **MVVM (Model–View–ViewModel)** | La pantalla no contiene lógica; se la pide a un "ViewModel" que prepara los datos y el estado. |
| **Offline-first** | La app funciona primero con datos locales y sincroniza con el servidor cuando hay red. |
| **Base de datos local** | Base de datos dentro del propio dispositivo móvil. |
| **Cola de sincronización** | Lista local de operaciones pendientes de enviar al servidor. |
| **Idempotencia** | Repetir una operación produce el mismo resultado que hacerla una sola vez. |
| **Identificador de transacción idempotente** | Código único que el cliente asigna a una operación para que el servidor no la registre dos veces si se reenvía. |
| **Transacción** | Conjunto de cambios en la base de datos que se aplican todos o ninguno. |
| **Degradación tolerante** | Ante un fallo, el sistema ofrece una versión reducida del servicio en vez de detenerse. |

## 6. Pendiente

- Diagrama de secuencia y diseño detallado de la cola de sincronización offline
  idempotente.
