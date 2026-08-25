from contextlib import asynccontextmanager
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database import init_db
from app.routers import admin, auth, course, dosen, gemini, interaction, kelas, module, recommendation


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title=settings.APP_NAME, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {"message": "Server Vocalearn Aktif"}


app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(course.router)
app.include_router(kelas.router)
app.include_router(module.router)
app.include_router(interaction.router)
app.include_router(recommendation.router)
app.include_router(gemini.router)
app.include_router(dosen.router)

_UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "uploads", "modules")
os.makedirs(_UPLOAD_DIR, exist_ok=True)
app.mount("/uploads/modules", StaticFiles(directory=_UPLOAD_DIR), name="module_uploads")
