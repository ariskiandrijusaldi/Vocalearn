import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asisten belajar berbasis NLP (§6 to-do list, Mini-PRD Fitur 2).
///
/// Untuk hackathon: respons berbasis template/keyword dulu (bukan mock
/// total kosong, tapi juga belum manggil LLM sungguhan) supaya bisa
/// didemokan tanpa tergantung backend.
///
/// TODO (Alya, koordinasi dengan Arrizki): ganti [AssistantRepository.ask]
/// agar memanggil endpoint backend, misalnya:
///   POST /assistant/ask  { "message": "...", "moduleId": "..." }
/// yang di baliknya backend Arrizki memanggil LLM API. Jangan panggil
/// LLM API langsung dari Flutter app — API key tidak boleh ditaruh di
/// sisi client.
class ChatMessage {
  final String text;
  final bool isUser;
  const ChatMessage({required this.text, required this.isUser});
}

class AssistantRepository {
  Future<String> ask(String question) async {
    await Future.delayed(const Duration(milliseconds: 600)); // simulasi network

    final q = question.toLowerCase();
    if (q.contains('subnet')) {
      return 'Subnetting itu cara membagi 1 jaringan besar jadi beberapa '
          'jaringan kecil. Coba mulai dari menentukan berapa subnet yang '
          'kamu butuhkan, lalu hitung subnet mask-nya. Mau saya bantu '
          'hitung contoh kasusnya?';
    }
    if (q.contains('routing')) {
      return 'Routing statis artinya kamu menentukan sendiri jalur data '
          'dari satu jaringan ke jaringan lain secara manual. Beda dengan '
          'routing dinamis yang dihitung otomatis oleh protokol seperti OSPF.';
    }
    if (q.contains('kabel') || q.contains('lan')) {
      return 'Untuk kabel LAN, pastikan urutan warna kabel di connector '
          'RJ45 sesuai standar (T568A atau T568B) dan konsisten di kedua '
          'ujung kalau kamu bikin kabel straight.';
    }
    return 'Pertanyaan bagus! Untuk sekarang aku masih pakai jawaban '
        'template dulu ya (versi hackathon) — nanti tim akan sambungkan '
        'ke AI beneran lewat backend. Coba tanya soal "subnetting", '
        '"routing", atau "kabel LAN" untuk lihat contoh jawabannya.';
  }
}

final assistantRepositoryProvider = Provider((ref) => AssistantRepository());

class AssistantChatController extends StateNotifier<List<ChatMessage>> {
  AssistantChatController(this._repository) : super([]);

  final AssistantRepository _repository;
  bool isLoading = false;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    state = [...state, ChatMessage(text: text, isUser: true)];

    isLoading = true;
    state = [...state]; // trigger rebuild untuk indikator loading di UI
    final reply = await _repository.ask(text);
    isLoading = false;

    state = [...state, ChatMessage(text: reply, isUser: false)];
  }
}

final assistantChatProvider =
StateNotifierProvider.family<AssistantChatController, List<ChatMessage>, String>(
      (ref, moduleId) => AssistantChatController(ref.read(assistantRepositoryProvider)),
);