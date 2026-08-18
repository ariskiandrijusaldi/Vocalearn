from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import settings
from app.database import init_db
from app.routers import admin, auth, course, gemini, interaction, module, recommendation


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title=settings.APP_NAME, lifespan=lifespan)


@app.get("/")
def root():
    return {"message": "Server Vocalearn Aktif"}


app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(course.router)
app.include_router(module.router)
app.include_router(interaction.router)
app.include_router(recommendation.router)
app.include_router(gemini.router)
