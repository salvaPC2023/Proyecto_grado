# Definition of Done (DoD)

Una historia de usuario está **`Hecha`** solo cuando cumple **todos** los puntos que apliquen a su capa.

## Común a toda historia

- [ ] Todos los criterios de aceptación (incluidos los de error) se verifican manualmente y quedan registrados en el acta de Sprint Review.
- [ ] El código está en el repositorio, en `main`, con al menos un commit cuyo mensaje referencia la historia (p. ej. `feat(ot): HU-05 crear OT con pasos`).
- [ ] Sin código muerto ni `TODO` pendientes que afecten el criterio de aceptación.
- [ ] Nombres, comentarios y estructura siguen el estilo del resto del módulo.
- [ ] Los secretos y valores de entorno salen de variables de entorno, nunca del código.

## Backend

- [ ] El código va en la rebanada de su módulo: `backend/src/modulos/<modulo>/{dominio,aplicacion,infraestructura}`. Lo transversal (conexión a BD, configuración, seguridad) vive en `backend/src/compartido/`.
- [ ] La lógica de negocio vive en `dominio/` y `aplicacion/` y no importa FastAPI, SQLAlchemy ni librerías externas (dependencias hacia adentro). Cada servicio externo (BD, IA) se usa a través de un puerto del `dominio/` con su adaptador en `infraestructura/`.
- [ ] El endpoint responde con los códigos HTTP definidos en el criterio de aceptación (200/201/400/401/403/404/409/422/503).
- [ ] Si la historia cambia el esquema de datos, hay una migración de Alembic y se aplicó en local.
- [ ] Probado a mano desde `/docs` (Swagger) con un caso correcto y uno de error.

## App móvil

- [ ] Separación MVVM: la pantalla no llama a la API ni a la base de datos; lo hace el ViewModel (Riverpod Notifier) a través de un repositorio.
- [ ] Toda llamada asíncrona muestra estado de carga y estado de error visibles.
- [ ] La navegación nueva está registrada en `core/router.dart` con su guard de rol si corresponde.
- [ ] Probado en dispositivo o emulador Android contra el backend local, con el flujo feliz y al menos un flujo de error.

## Requerimientos no funcionales transversales (aplican como DoD del producto)

Cada punto corresponde a un RNF del informe (RNF-01…RNF-NN). El mapeo completo está en
[`historias-usuario.md`](historias-usuario.md) §5.

- [ ] **Seguridad (RNF-01…04):** autenticación con sesión firmada (JWT) en todo endpoint no público; contraseñas con hash bcrypt; secretos en variables de entorno; sesión con expiración.
- [ ] **Autorización (RNF-05):** cada endpoint valida el rol; acceso indebido responde 403.
- [ ] **Resiliencia (RNF-08):** la app funciona con respuestas lentas del backend (timeouts y estados de carga).
- [ ] **Operación sin conexión (RNF-09):** el cierre de paso se puede registrar sin red y sincroniza al reconectar (aplica desde que E4 esté `Hecha`).
- [ ] **Tiempo de respuesta (RNF-06/07):** los endpoints (salvo la llamada a la IA) responden dentro del límite fijado en el informe; la estandarización con IA usa timeout de 8 s con degradación (HU-13).

> Los RNF que requieren verificación propia y medible (p. ej. tiempo de respuesta) además
> se registran como **tarjeta de restricción** en el Product Backlog. Ver la guía citada arriba.
