from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60
    default_technician_password: str = "ESPODI2026"
    # estandarización de descripciones; sin clave el backend arranca igual, pero no podrá estandarizar
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    openai_timeout_segundos: float = 8

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
