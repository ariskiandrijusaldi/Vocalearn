import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'student_list_screen.dart';
import 'material_detail_screen.dart';
import 'upload_materi_screen.dart';

import '../../models/materi_model.dart';
import '../../providers/materi_provider.dart';


// ============================================================
// MODEL MAHASISWA
// ============================================================

class MahasiswaKompetensi {
  final String nama;
  final String mataKuliah;
  final double skor;
  final String status;

  const MahasiswaKompetensi({
    required this.nama,
    required this.mataKuliah,
    required this.skor,
    required this.status,
  });
}


// ============================================================
// DATA DUMMY MAHASISWA
// ============================================================

const dummyMahasiswaDosen = [

  MahasiswaKompetensi(
    nama: 'Budi Santoso',
    mataKuliah: 'Praktik Pemrograman Dasar',
    skor: 0.85,
    status: 'Dikuasai',
  ),

  MahasiswaKompetensi(
    nama: 'Siti Aminah',
    mataKuliah: 'Praktik Pemrograman Dasar',
    skor: 0.55,
    status: 'Perlu Bantuan',
  ),

  MahasiswaKompetensi(
    nama: 'Andi Wijaya',
    mataKuliah: 'Praktik Pemrograman Dasar',
    skor: 0.25,
    status: 'Tertinggal',
  ),

  MahasiswaKompetensi(
    nama: 'Dewi Lestari',
    mataKuliah: 'Praktik Pemrograman Dasar',
    skor: 0.70,
    status: 'Dikuasai',
  ),

];


// ============================================================
// WARNA STATUS
// ============================================================

Color _statusColor(String status) {

  switch (status) {

    case 'Dikuasai':
      return Colors.green;

    case 'Perlu Bantuan':
      return Colors.orange;

    case 'Tertinggal':
      return Colors.red;

    default:
      return Colors.grey;

  }

}


// ============================================================
// DASHBOARD DOSEN
// ============================================================

class DosenDashboardScreen extends ConsumerWidget {

  const DosenDashboardScreen({
    super.key,
  });


  // ==========================================================
  // WARNA APLIKASI
  // ==========================================================

  static const Color cream =
  Color(0xFFEFE8DF);

  static const Color navy =
  Color(0xFF0F414A);

  static const Color blue =
  Color(0xFF96C0CE);


  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {


    // ========================================================
    // DATA MATERI
    // ========================================================

    final materi =
    ref.watch(materiProvider);


    // ========================================================
    // STATISTIK MAHASISWA
    // ========================================================

    final dikuasai =
        dummyMahasiswaDosen
            .where(
              (m) => m.status == 'Dikuasai',
        )
            .length;


    final perluBantuan =
        dummyMahasiswaDosen
            .where(
              (m) => m.status == 'Perlu Bantuan',
        )
            .length;


    final tertinggal =
        dummyMahasiswaDosen
            .where(
              (m) => m.status == 'Tertinggal',
        )
            .length;



    return Scaffold(

      backgroundColor:
      cream,


      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(

        backgroundColor:
        navy,

        foregroundColor:
        Colors.white,

        elevation: 0,

        title: const Text(

          'VocaLearn — Dosen',

          style: TextStyle(

            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),



      // ======================================================
      // BODY
      // ======================================================

      body: ListView(

        padding:
        const EdgeInsets.all(20),

        children: [


          // ==================================================
          // HEADER
          // ==================================================

          const Text(

            'Halo, Dosen 👋',

            style: TextStyle(

              fontSize: 24,

              fontWeight:
              FontWeight.w800,

              color:
              navy,

            ),

          ),


          const SizedBox(height: 6),


          const Text(

            'Berikut peta kompetensi kelas Anda saat ini.',

            style: TextStyle(

              fontSize: 13,

              color:
              Colors.black54,

            ),

          ),


          const SizedBox(height: 25),



          // ==================================================
          // MATA KULIAH
          // ==================================================

          Container(

            padding:
            const EdgeInsets.all(18),

            decoration:
            BoxDecoration(

              color:
              navy,

              borderRadius:
              BorderRadius.circular(20),

            ),


            child: Row(

              children: [

                Container(

                  padding:
                  const EdgeInsets.all(12),

                  decoration:
                  BoxDecoration(

                    color:
                    blue,

                    borderRadius:
                    BorderRadius.circular(14),

                  ),

                  child: const Icon(

                    Icons.menu_book_rounded,

                    color:
                    navy,

                    size: 28,

                  ),

                ),


                const SizedBox(width: 15),


                const Expanded(

                  child: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Mata Kuliah',

                        style: TextStyle(

                          color:
                          Colors.white70,

                          fontSize: 12,

                        ),

                      ),

                      SizedBox(height: 4),

                      Text(

                        'Praktik Pemrograman Dasar',

                        style: TextStyle(

                          color:
                          Colors.white,

                          fontWeight:
                          FontWeight.bold,

                          fontSize: 16,

                        ),

                      ),

                      SizedBox(height: 3),

                      Text(

                        'Kelas TI-2A',

                        style: TextStyle(

                          color:
                          Colors.white70,

                          fontSize: 12,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

          ),



          const SizedBox(height: 25),



          // ==================================================
          // MATERI PEMBELAJARAN
          // ==================================================

          Row(

            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [

              const Text(

                'Materi Pembelajaran',

                style: TextStyle(

                  fontSize: 18,

                  fontWeight:
                  FontWeight.bold,

                  color:
                  navy,

                ),

              ),


              TextButton.icon(

                onPressed: () {

                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (_) => const UploadMateriScreen(),

                    ),

                  );

                },

                icon: const Icon(

                  Icons.add,

                  size: 18,

                ),

                label: const Text(
                  'Tambah',
                ),

                style: TextButton.styleFrom(

                  foregroundColor:
                  navy,

                ),

              ),

            ],

          ),



          const SizedBox(height: 10),



          // ==================================================
          // JIKA BELUM ADA MATERI
          // ==================================================

          if (materi.isEmpty)

            Container(

              padding:
              const EdgeInsets.all(25),

              decoration:
              BoxDecoration(

                color:
                Colors.white,

                borderRadius:
                BorderRadius.circular(18),

              ),

              child: const Column(

                children: [

                  Icon(

                    Icons.folder_open,

                    size: 45,

                    color:
                    Colors.black38,

                  ),

                  SizedBox(height: 10),

                  Text(

                    'Belum ada materi',

                    style: TextStyle(

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),

                  SizedBox(height: 4),

                  Text(

                    'Tambahkan materi pembelajaran untuk kelas Anda.',

                    textAlign:
                    TextAlign.center,

                    style: TextStyle(

                      fontSize: 12,

                      color:
                      Colors.black54,

                    ),

                  ),

                ],

              ),

            ),



          // ==================================================
          // DAFTAR MATERI
          // ==================================================

          ...materi.map(

                (MateriModel item) {

              return Container(

                margin:
                const EdgeInsets.only(
                  bottom: 10,
                ),

                decoration:
                BoxDecoration(

                  color:
                  Colors.white,

                  borderRadius:
                  BorderRadius.circular(18),

                ),

                child: InkWell(

                  borderRadius:
                  BorderRadius.circular(18),

                  onTap: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            MaterialDetailScreen(

                              materi:
                              item,

                            ),

                      ),

                    );

                  },


                  child: Padding(

                    padding:
                    const EdgeInsets.all(15),

                    child: Row(

                      children: [

                        // ICON FILE

                        Container(

                          padding:
                          const EdgeInsets.all(12),

                          decoration:
                          BoxDecoration(

                            color:
                            blue.withOpacity(.30),

                            borderRadius:
                            BorderRadius.circular(13),

                          ),

                          child: const Icon(

                            Icons.picture_as_pdf,

                            color:
                            navy,

                          ),

                        ),


                        const SizedBox(width: 12),


                        // INFORMASI MATERI

                        Expanded(

                          child: Column(

                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(

                                item.judul,

                                maxLines: 1,

                                overflow:
                                TextOverflow.ellipsis,

                                style:
                                const TextStyle(

                                  fontWeight:
                                  FontWeight.bold,

                                  color:
                                  navy,

                                ),

                              ),


                              const SizedBox(height: 4),


                              Text(

                                item.deskripsi,

                                maxLines: 2,

                                overflow:
                                TextOverflow.ellipsis,

                                style:
                                const TextStyle(

                                  fontSize: 12,

                                  color:
                                  Colors.black54,

                                ),

                              ),


                              const SizedBox(height: 7),


                              Row(

                                children: [

                                  const Icon(

                                    Icons.auto_awesome,

                                    size: 14,

                                    color:
                                    navy,

                                  ),

                                  const SizedBox(width: 5),

                                  Text(

                                    item.statusAI,

                                    style:
                                    const TextStyle(

                                      fontSize: 11,

                                      color:
                                      navy,

                                      fontWeight:
                                      FontWeight.w600,

                                    ),

                                  ),

                                ],

                              ),

                            ],

                          ),

                        ),


                        const Icon(

                          Icons.chevron_right,

                          color:
                          navy,

                        ),

                      ],

                    ),

                  ),

                ),

              );

            },

          ),



          const SizedBox(height: 20),



          // ==================================================
          // MONITORING MAHASISWA
          // ==================================================

          const Text(

            'Monitoring Mahasiswa',

            style: TextStyle(

              fontSize: 18,

              fontWeight:
              FontWeight.bold,

              color:
              navy,

            ),

          ),


          const SizedBox(height: 12),



          // ==================================================
          // SUMMARY CARD
          // ==================================================

          Row(

            children: [


              _buildSummaryCard(

                label:
                'Dikuasai',

                count:
                dikuasai,

                color:
                Colors.green,

                icon:
                Icons.check_circle,

              ),


              const SizedBox(width: 8),


              _buildSummaryCard(

                label:
                'Perlu Bantuan',

                count:
                perluBantuan,

                color:
                Colors.orange,

                icon:
                Icons.warning_rounded,

              ),


              const SizedBox(width: 8),


              _buildSummaryCard(

                label:
                'Tertinggal',

                count:
                tertinggal,

                color:
                Colors.red,

                icon:
                Icons.error_rounded,

              ),

            ],

          ),



          const SizedBox(height: 15),



          // ==================================================
          // LIHAT SEMUA MAHASISWA
          // ==================================================

          SizedBox(

            width:
            double.infinity,

            child: OutlinedButton.icon(

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                    const StudentListScreen(),

                  ),

                );

              },


              icon: const Icon(

                Icons.groups_rounded,

              ),


              label: const Text(

                'Lihat Semua Mahasiswa',

              ),


              style:
              OutlinedButton.styleFrom(

                foregroundColor:
                navy,

                side:
                const BorderSide(
                  color: navy,
                ),

                padding:
                const EdgeInsets.symmetric(
                  vertical: 14,
                ),

                shape:
                RoundedRectangleBorder(

                  borderRadius:
                  BorderRadius.circular(15),

                ),

              ),

            ),

          ),



          const SizedBox(height: 25),



          // ==================================================
          // DAFTAR MAHASISWA
          // ==================================================

          const Text(

            'Daftar Mahasiswa',

            style: TextStyle(

              fontSize: 18,

              fontWeight:
              FontWeight.bold,

              color:
              navy,

            ),

          ),


          const SizedBox(height: 12),



          ...dummyMahasiswaDosen.map(

                (mhs) => _buildMahasiswaCard(

              context,

              mhs,

            ),

          ),



          const SizedBox(height: 20),



          // ==================================================
          // AI INSIGHT
          // ==================================================

          Container(

            padding:
            const EdgeInsets.all(18),

            decoration:
            BoxDecoration(

              color:
              blue.withOpacity(.25),

              borderRadius:
              BorderRadius.circular(20),

            ),

            child: Row(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Container(

                  padding:
                  const EdgeInsets.all(10),

                  decoration:
                  BoxDecoration(

                    color:
                    Colors.white,

                    borderRadius:
                    BorderRadius.circular(12),

                  ),

                  child: const Icon(

                    Icons.auto_awesome,

                    color:
                    navy,

                  ),

                ),


                const SizedBox(width: 12),


                const Expanded(

                  child: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(

                        'AI Learning Insight',

                        style: TextStyle(

                          fontWeight:
                          FontWeight.bold,

                          color:
                          navy,

                        ),

                      ),

                      SizedBox(height: 5),

                      Text(

                        'Hasil analisis dan rekomendasi pembelajaran dari AI akan ditampilkan di bagian ini.',

                        style: TextStyle(

                          fontSize: 12,

                          height: 1.5,

                          color:
                          navy,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  // ==========================================================
  // SUMMARY CARD
  // ==========================================================

  Widget _buildSummaryCard({

    required String label,

    required int count,

    required Color color,

    required IconData icon,

  }) {

    return Expanded(

      child: Container(

        padding:
        const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 5,
        ),

        decoration:
        BoxDecoration(

          color:
          Colors.white,

          borderRadius:
          BorderRadius.circular(16),

        ),

        child: Column(

          children: [

            Icon(

              icon,

              color:
              color,

              size: 22,

            ),


            const SizedBox(height: 7),


            Text(

              '$count',

              style: TextStyle(

                fontSize: 23,

                fontWeight:
                FontWeight.bold,

                color:
                color,

              ),

            ),


            const SizedBox(height: 3),


            Text(

              label,

              textAlign:
              TextAlign.center,

              style: const TextStyle(

                fontSize: 10,

                color:
                Colors.black54,

              ),

            ),

          ],

        ),

      ),

    );

  }



  // ==========================================================
  // MAHASISWA CARD
  // ==========================================================

  Widget _buildMahasiswaCard(

      BuildContext context,

      MahasiswaKompetensi mhs,

      ) {

    return Container(

      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
      const EdgeInsets.all(15),

      decoration:
      BoxDecoration(

        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(16),

      ),

      child: InkWell(

        borderRadius:
        BorderRadius.circular(16),

        onTap: () {

          // Nanti diarahkan ke detail mahasiswa

        },


        child: Row(

          children: [

            // AVATAR

            CircleAvatar(

              radius: 22,

              backgroundColor:
              _statusColor(
                mhs.status,
              ).withOpacity(.15),

              child: Icon(

                Icons.person,

                color:
                _statusColor(
                  mhs.status,
                ),

              ),

            ),


            const SizedBox(width: 12),


            // INFORMASI

            Expanded(

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(

                    mhs.nama,

                    style:
                    const TextStyle(

                      fontWeight:
                      FontWeight.w600,

                      fontSize: 15,

                      color:
                      navy,

                    ),

                  ),


                  const SizedBox(height: 3),


                  Text(

                    mhs.mataKuliah,

                    style:
                    const TextStyle(

                      fontSize: 11,

                      color:
                      Colors.black54,

                    ),

                  ),


                  const SizedBox(height: 8),


                  // PROGRESS

                  ClipRRect(

                    borderRadius:
                    BorderRadius.circular(10),

                    child:
                    LinearProgressIndicator(

                      value:
                      mhs.skor,

                      minHeight: 6,

                      backgroundColor:
                      Colors.black12,

                      color:
                      _statusColor(
                        mhs.status,
                      ),

                    ),

                  ),

                ],

              ),

            ),


            const SizedBox(width: 12),


            Column(

              children: [

                Text(

                  '${(mhs.skor * 100).toInt()}%',

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.bold,

                    color:
                    navy,

                  ),

                ),


                const SizedBox(height: 5),


                Container(

                  padding:
                  const EdgeInsets.symmetric(

                    horizontal: 8,

                    vertical: 4,

                  ),

                  decoration:
                  BoxDecoration(

                    color:
                    _statusColor(
                      mhs.status,
                    ),

                    borderRadius:
                    BorderRadius.circular(20),

                  ),

                  child: Text(

                    mhs.status,

                    style:
                    const TextStyle(

                      color:
                      Colors.white,

                      fontSize: 9,

                      fontWeight:
                      FontWeight.w600,

                    ),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

}