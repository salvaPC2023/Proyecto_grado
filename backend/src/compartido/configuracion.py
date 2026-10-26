from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    # un técnico puede pasar horas sin señal: la cola de cierres se envía con este token (tarjeta 27)
    jwt_expire_minutes: int = 240
    default_technician_password: str = "ESPODI2026"
    # administrador que se crea al arrancar si no hay ninguno; sin contraseña no se crea
    admin_usuario_inicial: str = "admin"
    admin_password_inicial: str = ""
    # estandarización de descripciones; sin clave el backend arranca igual, pero no podrá estandarizar
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    openai_timeout_segundos: float = 12
    # carpeta donde se guardan las imágenes de los comunicados (relativa a la carpeta backend)
    comunicados_imagenes_dir: str = "datos/imagenes_comunicados"
    # notificaciones push (tarjeta 23): clave de la cuenta de servicio de Firebase; nunca se sube a git
    firebase_credenciales: str = "secrets/firebase.json"
    notificaciones_intervalo_minutos: float = 5

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
