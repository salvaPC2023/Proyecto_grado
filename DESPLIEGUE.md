# Despliegue para las pruebas con usuarios y la defensa

El backend, PostgreSQL y las imágenes de los comunicados corren en la laptop, como en desarrollo.
**ngrok** le da a la laptop una dirección pública fija con HTTPS, y el APK apunta a esa dirección.
Así los celulares se conectan desde cualquier red (datos móviles o WiFi), sin servidor pago.

```
Celulares (APK) ──HTTPS──> https://<tu-dominio>.ngrok-free.app ──túnel──> laptop: uvicorn :8000 ──> PostgreSQL
```

La arquitectura del sistema sigue siendo un monolito modular pensado para una PaaS; este es el
entorno de demostración, elegido por presupuesto. El mismo APK y el mismo backend funcionan en
una PaaS cambiando solo `API_URL` y las variables de entorno.

---

## 1. Preparación (una sola vez)

### 1.1 ngrok

1. Crear una cuenta gratuita en https://ngrok.com e iniciar sesión.
2. Instalar ngrok en Windows:
   ```powershell
   winget install ngrok.ngrok
   ```
3. Conectar la instalación con la cuenta (el token está en el panel de ngrok, sección *Your Authtoken*):
   ```powershell
   ngrok config add-authtoken <TU_TOKEN>
   ```
4. En el panel de ngrok, sección **Domains**, anotar el dominio gratuito asignado
   (por ejemplo `nombre-asignado.ngrok-free.app`). **No cambia**, y el APK se compila con él.

Límites del plan gratuito: 1 GB de transferencia y 20 000 peticiones al mes. Para un supervisor y
tres técnicos alcanza de sobra; lo que más consume son las imágenes de los comunicados, así que
conviene que pesen poco (fotos de celular reducidas, menos de 500 KB).

### 1.2 Llave de firma del APK

El APK de release se firma con una llave propia. **Si se pierde, no se pueden instalar actualizaciones
encima de la versión ya instalada** (habría que desinstalar la app y perder la sesión guardada).

1. Crear la llave (usa el `keytool` que trae Android Studio). Pide una contraseña y unos datos; anótalos:
   ```powershell
   New-Item -ItemType Directory -Force C:\Users\Salva\llaves
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore C:\Users\Salva\llaves\espodi-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias espodi
   ```
2. Crear `mobile/android/key.properties` (está en `.gitignore`, **nunca se sube**):
   ```properties
   storeFile=C:/Users/Salva/llaves/espodi-release.jks
   storePassword=<la contraseña de la llave>
   keyAlias=espodi
   keyPassword=<la misma contraseña>
   ```
3. **Respaldar** `espodi-release.jks` y la contraseña en un lugar privado fuera de la laptop
   (USB o tu Drive personal). Sin `key.properties`, el release se firma con la llave de desarrollo:
   funciona, pero no es la de la entrega.

### 1.3 Compilar el APK

Desde `mobile`, con el dominio de ngrok:

```powershell
flutter build apk --release --dart-define=API_URL=https://<tu-dominio>.ngrok-free.app/api/v1
```

El archivo queda en `mobile/build/app/outputs/flutter-apk/app-release.apk`.
Sin `--dart-define`, la app usa `http://localhost:8000/api/v1` (desarrollo con el emulador).

### 1.4 Instalar en los celulares

1. Enviar `app-release.apk` por Google Drive o WhatsApp.
2. En el celular, abrir el archivo. Android pide permitir **instalar apps de origen desconocido**
   para esa aplicación (Drive, WhatsApp o Archivos): permitirlo.
3. Si **Play Protect** avisa que la app no está verificada: *Más detalles → Instalar de todas formas*.
   Es normal en apps que no vienen de la Play Store.

---

## 2. El día anterior a cada evento

- [ ] Preparar los datos (ver sección 5: vaciar e importar `prueba_importacion.xlsx` o los datos reales).
- [ ] Ensayar el flujo completo **con un celular usando datos móviles**, no el WiFi de la casa:
      primer ingreso, crear OT, cerrar un paso con estandarización, comunicado con imagen, exportar Excel.
- [ ] Dejar Windows actualizado y reiniciado (evita que una actualización reinicie la laptop durante el evento).
- [ ] Revisar que la laptop tenga internet en el lugar del evento, y que los usuarios tengan datos o WiFi.
- [ ] Tener un **video grabado del flujo completo**, por si falla la red el día de la defensa.

---

## 3. El día del evento, en este orden

### 3.1 Evitar que la laptop se suspenda

Con la laptop **enchufada**, en PowerShell:

```powershell
powercfg /change standby-timeout-ac 0     # no suspender
powercfg /change hibernate-timeout-ac 0   # no hibernar
```

Si se va a cerrar la tapa: *Panel de control → Opciones de energía → Elegir el comportamiento del
cierre de la tapa → "Al cerrar la tapa: No hacer nada" (Conectado)*.

Al terminar el evento, volver a lo normal (por ejemplo, suspender a los 30 minutos):

```powershell
powercfg /change standby-timeout-ac 30
powercfg /change hibernate-timeout-ac 60
```

### 3.2 PostgreSQL

```powershell
Get-Service postgresql-x64-17
```

Debe decir `Running`. Si no: `Start-Service postgresql-x64-17` (PowerShell como administrador).

### 3.3 Backend (terminal 1)

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
uvicorn src.main:app
```

Sin `--reload`: en una demostración no conviene que se reinicie al guardar un archivo.
Esperar `Application startup complete`.

### 3.4 ngrok (terminal 2)

```powershell
ngrok http 8000 --url=https://<tu-dominio>.ngrok-free.app
```

Debe mostrar `Session Status: online` y `Forwarding https://<tu-dominio>... -> http://localhost:8000`.

### 3.5 Comprobar desde un celular

Abrir en el navegador del celular `https://<tu-dominio>.ngrok-free.app/health`
(si aparece el aviso de ngrok, tocar *Visit Site*). Debe responder `{"status":"ok"}`.
Luego abrir la app e iniciar sesión.

### 3.6 Durante el evento

- **Ver las peticiones en vivo:** en la laptop, abrir http://127.0.0.1:4040 (inspector de ngrok).
  Sirve para mostrar en la defensa qué responde el backend, o para encontrar un error.
- No cerrar las dos terminales ni la tapa (salvo que se haya configurado "No hacer nada").

---

## 4. Si algo falla

| Síntoma en la app | Revisar |
|---|---|
| "No se pudo conectar al servidor" | ¿Corre el backend (terminal 1)? ¿ngrok dice `online` (terminal 2)? ¿El celular tiene internet? ¿`/health` responde en el navegador del celular? |
| `/health` no responde | ngrok cerrado o laptop sin internet. Reiniciar ngrok con el mismo comando. |
| Error 502 en el inspector de ngrok | El backend no está corriendo en el puerto 8000. |
| La estandarización no funciona | Revisar `OPENAI_API_KEY` y el saldo de OpenAI. La app ofrece continuar con el texto original. |
| Las imágenes no cargan | Revisar que exista `backend/datos/imagenes_comunicados` y que el backend no se haya movido de carpeta. |

---

## 5. Vaciar la base y volver a cargar los datos

Con el backend detenido, desde `backend` con el entorno activo:

```powershell
alembic downgrade base
alembic upgrade head
Remove-Item -Recurse -Force datos\imagenes_comunicados -ErrorAction SilentlyContinue
```

Al volver a arrancar el backend se crea de nuevo el administrador con `ADMIN_USUARIO_INICIAL` y
`ADMIN_PASSWORD_INICIAL` del `.env` (deberá cambiar sus datos en el primer ingreso).
Después se importa el Excel desde la app (administrador → Excel).

---

## 6. Si más adelante se usa una PaaS (Railway u otra)

No cambia el código: se configuran las mismas variables del `.env` en el panel del proveedor,
un volumen persistente para `COMUNICADOS_IMAGENES_DIR`, el comando de arranque
`alembic upgrade head && uvicorn src.main:app --host 0.0.0.0 --port $PORT`, y se recompila el APK
con `--dart-define=API_URL=https://<dirección del proveedor>/api/v1`.
