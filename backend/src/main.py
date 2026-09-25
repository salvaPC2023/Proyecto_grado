from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.modulos.acceso_roles.infraestructura.router import router as acceso_roles_router

app = FastAPI(title="Maintenance App API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # solo para desarrollo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(acceso_roles_router, prefix="/api/v1")
# Los routers de los proximos modulos se agregan aca de la misma forma.


@app.get("/health")
def health_check():
    return {"status": "ok"}
