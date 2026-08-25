"""Penaksir kompetensi siswa.

Ada dua strategi yang bisa dipilih:
1. `weighted_mastery` — rata-rata skor tertimbang (makin baru makin berpengaruh).
   Deterministik, mudah dijelaskan, tanpa parameter.
2. `bkt_mastery` — Bayesian Knowledge Tracing (BKT). Menaksir probabilitas
   penguasaan (mastery) lewat pembaruan posterior per observasi.

Keduanya mengembalikan nilai 0..1 (1 = sudah dikuasai).
"""
from datetime import datetime
from typing import Iterable


def _age_hours(created_at: datetime, now: datetime | None = None) -> float:
    now = now or datetime.now()
    return max((now - created_at).total_seconds() / 3600.0, 0.0)


def weighted_mastery(
    scores: Iterable[float],
    timestamps: Iterable[datetime] | None = None,
    half_life_hours: float = 48.0,
) -> float:
    """Rata-rata tertimbang eksponensial (decay terhadap waktu).

    Skor yang lebih baru berbobot lebih besar -> menangkap progres terkini.
    """
    score_list = list(scores)
    if not score_list:
        raise ValueError("tidak ada skor untuk dihitung")

    ts_list = list(timestamps) if timestamps else None
    now = datetime.now()
    total_w, acc = 0.0, 0.0
    for i, score in enumerate(score_list):
        w = 1.0
        if ts_list and i < len(ts_list):
            w = 0.5 ** (_age_hours(ts_list[i], now) / half_life_hours)
        total_w += w
        acc += w * (score / 100.0)
    return acc / total_w if total_w else 0.0


DEFAULT_BKT_PARAMS = {
    "p_learn": 0.1,       # peluang mastery bertambah per kesempatan belajar
    "p_guess": 0.2,       # peluang benar walau belum menguasai (menebak)
    "p_slip": 0.1,        # peluang salah walau sudah menguasai
    "p_init": 0.3,        # prior awal penguasaan
}


def _bkt_step(prev: float, observation: float, params: dict) -> float:
    p_learn = params["p_learn"]
    p_guess = params["p_guess"]
    p_slip = params["p_slip"]

    p_correct_if_master = 1.0 - p_slip
    p_correct_if_not = p_guess

    if observation == 1.0:
        lik_master = p_correct_if_master
        lik_not = p_correct_if_not
    else:
        lik_master = p_slip
        lik_not = 1.0 - p_guess

    posterior = (prev * lik_master) / (prev * lik_master + (1 - prev) * lik_not)
    return posterior + (1.0 - posterior) * p_learn


def bkt_mastery(observations: Iterable[float], params: dict | None = None) -> float:
    """BKT sederhana: mastery probability akhir setelah deretan observasi (0/1).

    observasi 1 = menjawab benar (mis. skor >= 60), 0 = salah.
    """
    params = params or DEFAULT_BKT_PARAMS
    mastery = params.get("p_init", 0.3)
    for obs in observations:
        mastery = _bkt_step(mastery, 1.0 if obs >= 0.5 else 0.0, params)
    return mastery
