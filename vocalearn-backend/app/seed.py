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
    Jurusan,
    Kelas,
    Module,
    ModuleStatus,
    Prodi,
    User,
)
from app.models.answer_explanation import AnswerExplanation
from app.models.chat_message import ChatMessage
from app.models.diagnostic_result import DiagnosticResult
from app.models.quiz_attempt import QuizAttempt
from app.models.quiz_question import QuizQuestion
from app.models.simplified_material import SimplifiedMaterial
from app.security import hash_password

MASTER_PASSWORD = "admin123"

# Jurusan beserta program studi (prodi) yang berada di dalamnya.
JURUSANS = [
    {
        "name": "Teknologi Informasi",
        "prodi": [
            "S1 Teknik Informatika",
            "S1 Sistem Informasi",
"Manajemen Informatika",
        ],
    },
    {
        "name": "Akuntansi",
        "prodi": ["S1 Akuntansi", "D3 Akuntansi"],
    },
    {
        "name": "Teknik Sipil",
        "prodi": ["S1 Teknik Sipil"],
    },
    {
        "name": "Teknik Mesin",
        "prodi": ["S1 Teknik Mesin", "D3 Teknik Mesin"],
    },
]

COURSES = [
    {
        "code": "BING101",
        "name": "Bahasa Inggris Dasar",
        "prodi": "S1 Teknik Informatika",
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
        "prodi": "Manajemen Informatika",
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
        "prodi": "S1 Akuntansi",
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
        "prodi": "D3 Akuntansi",
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
        "prodi": "S1 Teknik Mesin",
        "semester": 4,
        "credits": 3,
        "skkni_unit": "Persiapan Sertifikasi Profesi Bahasa",
        "skkni_code": "K.06",
        "kkni_level": 5,
        "description": "Bahasa Korea untuk industri pariwisata & hospitality",
    },
]

# Format: (code, title, difficulty, status, order, kelas_name_or_None)
# kelas_name_or_None: modul ini hanya tampil untuk kelas tersebut; None = umum (semua kelas).
MODULES = [
    # Course 1: Bahasa Inggris Dasar — khusus TI-2A
    ("BING101", "Greetings & Introductions", 1, ModuleStatus.PUBLISHED, 0, "TI-2A"),
    ("BING101", "Present Simple Tense", 2, ModuleStatus.PUBLISHED, 1, "TI-2A"),
    ("BING101", "Vocabulary: Daily Activities", 3, ModuleStatus.REVIEW, 2, "TI-2A"),
    ("BING101", "Listening: Short Conversations", 4, ModuleStatus.DRAFT, 3, "TI-2A"),
    # Course 2: Bahasa Jepang Percakapan — umum (semua kelas)
    ("BJEP102", "Hiragana Dasar", 2, ModuleStatus.PUBLISHED, 0, None),
    ("BJEP102", "Salam & Perkenalan", 3, ModuleStatus.PUBLISHED, 1, None),
    ("BJEP102", "Katakana: Kata Serapan", 4, ModuleStatus.REVIEW, 2, None),
    # Course 3: Bahasa Mandarin Bisnis — khusus TI-2B
    ("BMAN103", "Pinyin & Nada", 3, ModuleStatus.PUBLISHED, 0, "TI-2B"),
    ("BMAN103", "Angka & Harga", 4, ModuleStatus.DRAFT, 1, "TI-2B"),
    # Course 4: Public Speaking — khusus TI-2A
    ("PKOR104", "Struktur Pidato", 2, ModuleStatus.PUBLISHED, 0, "TI-2A"),
    ("PKOR104", "Teknik Vokal & Gestur", 3, ModuleStatus.REVIEW, 1, "TI-2A"),
    # Course 5: Bahasa Korea Pariwisata — khusus TI-2B
    ("BKOR105", "Hangul Dasar", 4, ModuleStatus.PUBLISHED, 0, "TI-2B"),
    ("BKOR105", "Frasa Check-in Bandara", 5, ModuleStatus.PUBLISHED, 1, "TI-2B"),
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
        # Upsert agar kolom prodi ikut sinkron dengan jurusan terbaru.
        if user.prodi != prodi:
            user.prodi = prodi
            db.flush()
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

        # 3) Kelas
        kelas_map = {}
        for name, dosen_key, desc in (
            ("TI-2A", "dosen1", "Kelas Teknik Informatika 2A - Dikelola Dr. Sari"),
            ("TI-2B", "dosen2", "Kelas Teknik Informatika 2B - Dikelola Andi Pratama"),
        ):
            k = db.query(Kelas).filter(Kelas.name == name).first()
            if not k:
                k = Kelas(
                    name=name,
                    dosen_id=dosen_ids[dosen_key],
                    description=desc,
                )
                db.add(k)
                db.flush()
            kelas_map[name] = k

        # 4) Mahasiswa
        mahasiswa = [
            ("240001", "Rina Kartika", "S1 Teknik Informatika", "TI-2A"),
            ("240002", "Dimas Anggara", "S1 Sistem Informasi", "TI-2A"),
            ("240003", "Sinta Permata", "Manajemen Informatika", "TI-2B"),
            ("240004", "Budi Santoso", "S1 Teknik Sipil", "TI-2B"),
            ("240005", "Alya Rahma", "S1 Akuntansi", "TI-2A"),
        ]
        students = {}
        for i, (nim, name, prodi, kelas_name) in enumerate(mahasiswa, start=1):
            s = _get_user(db, nim, name, prodi, i)
            if s.kelas_id is None and kelas_name in kelas_map:
                s.kelas_id = kelas_map[kelas_name].id
                db.flush()
            students[nim] = s

        # 4) Jurusan & prodi
        for j in JURUSANS:
            jurusan = db.query(Jurusan).filter(Jurusan.name == j["name"]).first()
            if not jurusan:
                jurusan = Jurusan(name=j["name"])
                db.add(jurusan)
                db.flush()
            for prodi_name in j["prodi"]:
                prodi = db.query(Prodi).filter(Prodi.name == prodi_name).first()
                if not prodi:
                    db.add(Prodi(name=prodi_name, jurusan_id=jurusan.id))

        # 4a) Jurusan untuk dosen — keduanya mengampu kelas TI.
        #     Dosen hanya melihat MK dari jurusannya saat mengunggah modul.
        ti_jurusan = db.query(Jurusan).filter(Jurusan.name == "Teknologi Informasi").first()
        if ti_jurusan:
            for d in db.query(User).filter(User.role == User.DOSEN).all():
                if d.jurusan_id != ti_jurusan.id:
                    d.jurusan_id = ti_jurusan.id

        # 5) Mata kuliah
        course_map = {}
        for c in COURSES:
            course = db.query(Course).filter(Course.code == c["code"]).first()
            if not course:
                course = Course(**c)
                db.add(course)
                db.flush()
            else:
                # Upsert agar kolom baru (mis. prodi) ikut terisi pada DB lama.
                for field, value in c.items():
                    setattr(course, field, value)
            course_map[c["code"]] = course

        # 6) Modul
        module_by_title = {}
        for code, title, difficulty, status, order, kelas_name in MODULES:
            course = course_map[code]
            mod = (
                db.query(Module)
                .filter(Module.course_id == course.id, Module.title == title)
                .first()
            )
            if not mod:
                kelas_id = kelas_map[kelas_name].id if kelas_name and kelas_name in kelas_map else None
                mod = Module(
                    course_id=course.id,
                    title=title,
                    description=f"Modul praktik {title}",
                    content=f"Ringkasan materi {title} untuk latihan mandiri.",
                    difficulty=difficulty,
                    order_index=order,
                    status=status,
                    kelas_id=kelas_id,
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

        # 8) Interaksi / skor latihan
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

        # 8) Sample quiz questions (Bahasa Inggris Dasar — Greetings)
        greetings_mod = module_by_title.get("Greetings & Introductions")
        if greetings_mod:
            quiz_samples = [
                {
                    "pertanyaan": "Apa arti 'How are you?' dalam Bahasa Indonesia?",
                    "opsi_a": "Siapa namamu?",
                    "opsi_b": "Apa kabarmu?",
                    "opsi_c": "Dimana rumahmu?",
                    "opsi_d": "Berapa umurmu?",
                    "jawaban_benar": "B",
                    "penjelasan": "'How are you?' adalah sapaan untuk menanyakan kabar seseorang.",
                },
                {
                    "pertanyaan": "Manakah yang merupakan sapaan formal?",
                    "opsi_a": "Hey!",
                    "opsi_b": "What's up?",
                    "opsi_c": "Good morning, Sir.",
                    "opsi_d": "Yo!",
                    "jawaban_benar": "C",
                    "penjelasan": "'Good morning, Sir.' adalah sapaan formal yang cocok untuk situasi resmi.",
                },
                {
                    "pertanyaan": "Apa jawaban yang tepat untuk 'What is your name?'",
                    "opsi_a": "I am fine.",
                    "opsi_b": "My name is Rina.",
                    "opsi_c": "I like reading.",
                    "opsi_d": "I am 20 years old.",
                    "jawaban_benar": "B",
                    "penjelasan": "'What is your name?' menanyakan nama, jadi jawabannya adalah 'My name is ...'",
                },
            ]
            for i, q in enumerate(quiz_samples):
                exists = (
                    db.query(QuizQuestion)
                    .filter(
                        QuizQuestion.material_id == greetings_mod.id,
                        QuizQuestion.pertanyaan == q["pertanyaan"],
                    )
                    .first()
                )
                if not exists:
                    db.add(
                        QuizQuestion(
                            material_id=greetings_mod.id,
                            level="pemula",
                            **q,
                        )
                    )

        # 9) Sample simplified material
        if greetings_mod:
            exists = (
                db.query(SimplifiedMaterial)
                .filter(
                    SimplifiedMaterial.material_id == greetings_mod.id,
                    SimplifiedMaterial.student_id == students["240001"].id,
                )
                .first()
            )
            if not exists:
                db.add(
                    SimplifiedMaterial(
                        material_id=greetings_mod.id,
                        student_id=students["240001"].id,
                        konten_sederhana=(
                            "Greetings adalah sapaan dalam Bahasa Inggris. "
                            "Beberapa contoh:\n"
                            "- Hello / Hi = Halo\n"
                            "- Good morning = Selamat pagi\n"
                            "- How are you? = Apa kabar?\n"
                            "- My name is ... = Nama saya ...\n\n"
                            "Tips: Gunakan 'Good morning/afternoon/evening' "
                            "untuk sapaan formal, dan 'Hi/Hello' untuk santai."
                        ),
                    )
                )

        # 10) Sample quiz attempt + explanation
        quiz_q = db.query(QuizQuestion).first()
        if quiz_q:
            exists = (
                db.query(QuizAttempt)
                .filter(
                    QuizAttempt.student_id == students["240001"].id,
                    QuizAttempt.question_id == quiz_q.id,
                )
                .first()
            )
            if not exists:
                wrong_answer = "A" if quiz_q.jawaban_benar != "A" else "B"
                attempt = QuizAttempt(
                    student_id=students["240001"].id,
                    question_id=quiz_q.id,
                    jawaban_siswa=wrong_answer,
                    is_correct=False,
                )
                db.add(attempt)
                db.flush()
                db.add(
                    AnswerExplanation(
                        quiz_attempt_id=attempt.id,
                        penjelasan_ai=(
                            "Jawaban kamu kurang tepat. "
                            f"Jawaban yang benar adalah {quiz_q.jawaban_benar}, "
                            f"karena {quiz_q.pertanyaan.lower()}"
                        ),
                        tips="Perhatikan konteks pertanyaan dan pilihan jawaban dengan seksama.",
                    )
                )

        # 11) Sample chat messages
        student_rina = students["240001"]
        exists = (
            db.query(ChatMessage)
            .filter(ChatMessage.student_id == student_rina.id)
            .first()
        )
        if not exists:
            db.add(
                ChatMessage(
                    student_id=student_rina.id,
                    role="user",
                    pesan="Halo, bagaimana cara menyapa dalam Bahasa Inggris?",
                )
            )
            db.add(
                ChatMessage(
                    student_id=student_rina.id,
                    role="assistant",
                    pesan=(
                        "Halo! Ada beberapa cara menyapa dalam Bahasa Inggris:\n"
                        "- Formal: Good morning/afternoon/evening\n"
                        "- Santai: Hi, Hello, Hey\n"
                        "- Menanyakan kabar: How are you? / How's it going?\n\n"
                        "Mau latihan menyapa?"
                    ),
                )
            )

        # 12) Sample diagnostic result
        exists = (
            db.query(DiagnosticResult)
            .filter(DiagnosticResult.student_id == student_rina.id)
            .first()
        )
        if not exists:
            import json as _json

            db.add(
                DiagnosticResult(
                    student_id=student_rina.id,
                    kompetensi_skor=_json.dumps({
                        "grammar": 65,
                        "vocabulary": 78,
                        "listening": 55,
                        "speaking": 40,
                        "reading": 72,
                    }),
                    gaya_belajar="visual",
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
