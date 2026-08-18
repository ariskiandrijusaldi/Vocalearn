import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    APP_NAME: str = "Vocalearn Backend AI"
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./vocalearn.db")

    SECRET_KEY: str = os.getenv("JWT_SECRET", "ganti-dengan-secret-kuat-produksi")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440")
    )

    GEMINI_API_KEY: str | None = os.getenv("GEMINI_API_KEY")
    GEMINI_MODEL: str = "models/gemini-flash-latest"


settings = Settings()
