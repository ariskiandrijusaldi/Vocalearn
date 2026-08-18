"""Seed data dummy untuk pengembangan tim.

Cara pakai:
    cd vocalearn-backend
    .\\venv\\Scripts\\python.exe -m app.seed

Akun default:
    super admin : admin@vocalearn.id  / admin123
    dosen       : dosen1@vocalearn.id / dosen123
    mahasiswa   : mahasiswa1@vocalearn.id / siswa123 (dst, hingga 5)
"""
from app.database import SessionLocal, init_db
from app.models import (
    Course,
    Enrollment,
    Interaction,
    Module,
    ModuleStatus,
    User,
)
from app.security import hash_password

MASTER_PASSWORD = "admin123"

COURSES = [
    {
        "code": "BING101",
        "name": "Bahasa Inggris Dasar",
        "semester": 1,
        "credits": 3,
        "skkni_unit": "Komunikasi Efektif dalam Bahasa Asing",
        "skkni_code": "K.01",
        "kkni_level": 3,
        "description": "Pondasi tata bahasa dan kosakata bahasa Inggris",
    },
    {
        "code": "BJEP102",
        "name": "Bahasa Jepang Percakapan",
        "semester": 2,
        "credits": 2,
        "skkni_unit": "Interaksi Lisan Dasar (listening & speaking)",
        "skkni_code": "K.04",
        "kkni_level": 4,
        "description": "Hiragana, katakana, dan percakapan sehari-hari",
    },
    {
        "code": "BMAN103",
        "name": "Bahasa Mandarin Bisnis",
        "semester": 3,
        "credits": 3,
        "skkni_unit": "Menyusun Korespondensi Bisnis",
        "skkni_code": "K.02",
        "kkni_level": 5,
        "description": "Bahasa Mandarin untuk konteks bisnis dan negosiasi",
    },
    {
        "code": "PKOR104",
        "name": "Public Speaking",
        "semester": 2,
        "credits": 2,
        "skkni_unit": "Presentasi dalam Bahasa Asing",
        "skkni_code": "K.03",
        "kkni_level": 4,
        "description": "Keterampilan presentasi dan berbicara di depan umum",
    },
    {
        "code": "BKOR105",
        "name": "Bahasa Korea Pariwisata",
        "semester": 4,
        "credits": 3,
        "skkni_unit": "Persiapan Sertifikasi Profesi Bahasa",
        "skkni_code": "K.06",
        "kkni_level": 5,
        "description": "Bahasa Korea untuk industri pariwisata & hospitality",
    },
]

MODULES = [
    # Course 1: Bahasa Inggris Dasar
    ("BING101", "Greetings & Introductions", 1, ModuleStatus.PUBLISHED, 0),
    ("BING101", "Present Simple Tense", 2, ModuleStatus.PUBLISHED, 1),
    ("BING101", "Vocabulary: Daily Activities", 3, ModuleStatus.REVIEW, 2),
    ("BING101", "Listening: Short Conversations", 4, ModuleStatus.DRAFT, 3),
    # Course 2: Bahasa Jepang Percakapan
    ("BJEP102", "Hiragana Dasar", 2, ModuleStatus.PUBLISHED, 0),
    ("BJEP102", "Salam & Perkenalan", 3, ModuleStatus.PUBLISHED, 1),
    ("BJEP102", "Katakana: Kata Serapan", 4, ModuleStatus.REVIEW, 2),
    # Course 3: Bahasa Mandarin Bisnis
    ("BMAN103", "Pinyin & Nada", 3, ModuleStatus.PUBLISHED, 0),
    ("BMAN103", "Angka & Harga", 4, ModuleStatus.DRAFT, 1),
    # Course 4: Public Speaking
    ("PKOR104", "Struktur Pidato", 2, ModuleStatus.PUBLISHED, 0),
    ("PKOR104", "Teknik Vokal & Gestur", 3, ModuleStatus.REVIEW, 1),
    # Course 5: Bahasa Korea Pariwisata
    ("BKOR105", "Hangul Dasar", 4, ModuleStatus.PUBLISHED, 0),
    ("BKOR105", "Frasa Check-in Bandara", 5, ModuleStatus.PUBLISHED, 1),
]

# format: (nim, list of (module_title, score, correct, total))
INTERACTIONS = {
    "240001": [
        ("Greetings & Introductions", 88, 11, 12),
        ("Present Simple Tense", 55, 7, 12),
        ("Present Simple Tense", 42, 5, 12),
        ("Hiragana Dasar", 90, 9, 10),
        ("Struktur Pidato", 75, 9, 12),
    ],
    "240002": [
        ("Greetings & Introductions", 95, 12, 12),
        ("Present Simple Tense", 85, 10, 12),
        ("Hiragana Dasar", 70, 7, 10),
    ],
    "240003": [
        ("Greetings & Introductions", 45, 5, 12),
        ("Present Simple Tense", 30, 4, 12),
        ("Present Simple Tense", 38, 5, 12),
        ("Vocabulary: Daily Activities", 50, 6, 12),
    ],
    "240004": [
        ("Hangul Dasar", 92, 9, 10),
        ("Frasa Check-in Bandara", 80, 8, 10),
    ],
    "240005": [],
}


def _get_user(db, nim: str, full_name: str, prodi: str, index: int) -> User:
    user = db.query(User).filter(User.nim == nim).first()
    if user:
        return user
    user = User(
        email=f"mahasiswa{index}@vocalearn.id",
        password_hash=hash_password("siswa123"),
        full_name=full_name,
        role=User.MAHASISWA,
        nim=nim,
        prodi=prodi,
    )
    db.add(user)
    db.flush()
    return user


def seed():
    init_db()
    db = SessionLocal()
    try:
        # 1) Super admin
        if not db.query(User).filter(User.email == "admin@vocalearn.id").first():
            db.add(
                User(
                    email="admin@vocalearn.id",
                    password_hash=hash_password(MASTER_PASSWORD),
                    full_name="Arrizki (Super Admin)",
                    role=User.SUPER_ADMIN,
                )
            )

        # 2) Dosen
        dosen_ids = {}
        for key, email, name, nip in (
            ("dosen1", "dosen1@vocalearn.id", "Dr. Sari Wulandari, M.Pd.", "19850512"),
            ("dosen2", "dosen2@vocalearn.id", "Andi Pratama, S.S., M.Hum.", "19880723"),
        ):
            d = db.query(User).filter(User.email == email).first()
            if not d:
                d = User(
                    email=email,
                    password_hash=hash_password("dosen123"),
                    full_name=name,
                    role=User.DOSEN,
                    nip=nip,
                    prodi="S1 Bahasa & Sastra",
                )
                db.add(d)
                db.flush()
            dosen_ids[key] = d.id

        # 3) Mahasiswa
        mahasiswa = [
            ("240001", "Rina Kartika", "S1 Bahasa Inggris"),
            ("240002", "Dimas Anggara", "S1 Pariwisata"),
            ("240003", "Sinta Permata", "S1 Manajemen Bisnis"),
            ("240004", "Budi Santoso", "S1 Hospitality"),
            ("240005", "Alya Rahma", "S1 Bahasa Inggris"),
        ]
        students = {}
        for i, (nim, name, prodi) in enumerate(mahasiswa, start=1):
            s = _get_user(db, nim, name, prodi, i)
            students[nim] = s

        # 4) Mata kuliah
        course_map = {}
        for c in COURSES:
            course = db.query(Course).filter(Course.code == c["code"]).first()
            if not course:
                course = Course(**c)
                db.add(course)
                db.flush()
            course_map[c["code"]] = course

        # 5) Modul
        module_by_title = {}
        for code, title, difficulty, status, order in MODULES:
            course = course_map[code]
            mod = (
                db.query(Module)
                .filter(Module.course_id == course.id, Module.title == title)
                .first()
            )
            if not mod:
                mod = Module(
                    course_id=course.id,
                    title=title,
                    description=f"Modul praktik {title}",
                    content=f"Ringkasan materi {title} untuk latihan mandiri.",
                    difficulty=difficulty,
                    order_index=order,
                    status=status,
                    created_by=dosen_ids["dosen1"] if code in ("BING101", "PKOR104") else dosen_ids["dosen2"],
                )
                db.add(mod)
                db.flush()
            module_by_title[title] = mod

        # 6) Enrollments
        enroll_map = {
            "240001": ["BING101", "BJEP102", "PKOR104"],
            "240002": ["BING101", "BJEP102"],
            "240003": ["BING101", "BMAN103"],
            "240004": ["BKOR105"],
            "240005": ["BING101", "BJEP102", "PKOR104"],
        }
        for nim, codes in enroll_map.items():
            for code in codes:
                exists = (
                    db.query(Enrollment)
                    .filter(
                        Enrollment.student_id == students[nim].id,
                        Enrollment.course_id == course_map[code].id,
                    )
                    .first()
                )
                if not exists:
                    db.add(
                        Enrollment(
                            student_id=students[nim].id,
                            course_id=course_map[code].id,
                        )
                    )

        # 7) Interaksi / skor latihan
        for nim, records in INTERACTIONS.items():
            student = students[nim]
            for title, score, correct, total in records:
                mod = module_by_title[title]
                exists = (
                    db.query(Interaction)
                    .filter(
                        Interaction.student_id == student.id,
                        Interaction.module_id == mod.id,
                        Interaction.score == score,
                    )
                    .first()
                )
                if not exists:
                    db.add(
                        Interaction(
                            student_id=student.id,
                            module_id=mod.id,
                            score=score,
                            correct_count=correct,
                            total_questions=total,
                            duration_seconds=5 * 60,
                        )
                    )

        db.commit()
        print("Seed berhasil!")
        print("  Super Admin : admin@vocalearn.id / admin123")
        print("  Dosen       : dosen1@vocalearn.id / dosen123")
        print("  Mahasiswa   : mahasiswa1@vocalearn.id / siswa123 (s/d 5)")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
