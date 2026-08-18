import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dosen_dashboard_screen.dart'
    show MahasiswaKompetensi;

import 'student_list_screen.dart'
    show statusColor;



class StudentDetailScreen extends ConsumerWidget {

  final MahasiswaKompetensi mahasiswa;


  const StudentDetailScreen({
    super.key,
    required this.mahasiswa,
  });



  static const cream =
  Color(0xFFEFE8DF);

  static const navy =
  Color(0xFF0F414A);

  static const blue =
  Color(0xFF96C0CE);

  static const beige =
  Color(0xFFDBA98A);

  static const maroon =
  Color(0xFF7F0303);



  @override
  Widget build(
      BuildContext context,
      WidgetRef ref
      ){


    final modul = [

      {
        "nama":"Dasar Variabel",
        "nilai":0.90,
        "status":"Selesai"
      },


      {
        "nama":"Percabangan",
        "nilai":mahasiswa.skor,
        "status":"Berjalan"
      },


      {
        "nama":"Perulangan",
        "nilai":0.40,
        "status":"Perlu Latihan"
      },


    ];




    return Scaffold(

      backgroundColor:
      cream,


      body:SafeArea(

        child:ListView(

          padding:
          const EdgeInsets.all(20),


          children:[



            // =====================
            // HEADER
            // =====================


            Row(

              children:[


                GestureDetector(

                  onTap:(){

                    Navigator.pop(context);

                  },


                  child:Container(

                    padding:
                    const EdgeInsets.all(12),


                    decoration:
                    BoxDecoration(

                      color:
                      Colors.white,

                      borderRadius:
                      BorderRadius.circular(15),

                    ),


                    child:
                    const Icon(

                      Icons.arrow_back_ios_new,

                      size:18,

                      color:navy,

                    ),

                  ),

                ),



                const SizedBox(width:15),



                const Text(

                  "Detail Mahasiswa",

                  style:
                  TextStyle(

                    color:navy,

                    fontSize:22,

                    fontWeight:
                    FontWeight.w800,

                  ),

                )


              ],

            ),



            const SizedBox(height:25),




            // =====================
            // PROFILE CARD
            // =====================


            Container(

              padding:
              const EdgeInsets.all(20),


              decoration:
              BoxDecoration(

                color:
                navy,

                borderRadius:
                BorderRadius.circular(25),

              ),


              child:Column(

                children:[



                  CircleAvatar(

                    radius:38,

                    backgroundColor:
                    blue,


                    child:
                    const Icon(

                      Icons.person,

                      size:45,

                      color:navy,

                    ),

                  ),



                  const SizedBox(height:15),



                  Text(

                    mahasiswa.nama,

                    style:
                    const TextStyle(

                      color:
                      Colors.white,

                      fontSize:20,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),



                  const SizedBox(height:5),



                  Text(

                    mahasiswa.mataKuliah,

                    style:
                    TextStyle(

                      color:
                      Colors.white.withOpacity(.8),

                      fontSize:12,

                    ),

                  )


                ],

              ),

            ),




            const SizedBox(height:20),




            // =====================
            // SCORE CARD
            // =====================


            Container(

              padding:
              const EdgeInsets.all(20),


              decoration:
              BoxDecoration(

                color:
                Colors.white,

                borderRadius:
                BorderRadius.circular(22),

              ),


              child:Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,


                children:[


                  const Text(

                    "Kompetensi Saat Ini",

                    style:
                    TextStyle(

                      color:navy,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),


                  const SizedBox(height:15),



                  Center(

                    child:Text(

                      "${(mahasiswa.skor*100).toInt()}%",

                      style:
                      const TextStyle(

                        fontSize:45,

                        fontWeight:
                        FontWeight.w900,

                        color:navy,

                      ),

                    ),

                  ),



                  const SizedBox(height:15),



                  ClipRRect(

                    borderRadius:
                    BorderRadius.circular(20),


                    child:
                    LinearProgressIndicator(

                      minHeight:12,

                      value:
                      mahasiswa.skor,


                      backgroundColor:
                      Colors.black12,


                      color:
                      statusColor(
                          mahasiswa.status
                      ),

                    ),

                  ),



                  const SizedBox(height:15),



                  Center(

                    child:Container(

                      padding:
                      const EdgeInsets.symmetric(

                        horizontal:18,

                        vertical:8,

                      ),


                      decoration:
                      BoxDecoration(

                        color:
                        statusColor(
                            mahasiswa.status
                        ),

                        borderRadius:
                        BorderRadius.circular(30),

                      ),


                      child:
                      Text(

                        mahasiswa.status,

                        style:
                        const TextStyle(

                          color:
                          Colors.white,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),

                    ),

                  )


                ],

              ),

            ),




            const SizedBox(height:25),




            // =====================
            // RIWAYAT MODUL
            // =====================


            const Text(

              "Riwayat Modul",

              style:
              TextStyle(

                color:navy,

                fontSize:18,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(height:12),



            ...modul.map(

                    (item)=>

                    Container(

                      margin:
                      const EdgeInsets.only(
                          bottom:12
                      ),


                      padding:
                      const EdgeInsets.all(16),


                      decoration:
                      BoxDecoration(

                        color:
                        Colors.white,

                        borderRadius:
                        BorderRadius.circular(18),

                      ),


                      child:Row(

                        children:[


                          Expanded(

                            child:Column(

                              crossAxisAlignment:
                              CrossAxisAlignment.start,


                              children:[


                                Text(

                                  item["nama"].toString(),

                                  style:
                                  const TextStyle(

                                    fontWeight:
                                    FontWeight.bold,

                                  ),

                                ),


                                const SizedBox(height:5),



                                Text(

                                  item["status"].toString(),

                                  style:
                                  const TextStyle(

                                    fontSize:12,

                                    color:
                                    Colors.black54,

                                  ),

                                )


                              ],

                            ),

                          ),



                          Text(

                            "${((item["nilai"] as double)*100).toInt()}%",

                            style:
                            const TextStyle(

                              fontWeight:
                              FontWeight.bold,

                              color:navy,

                            ),

                          )


                        ],

                      ),

                    )

            ),





            const SizedBox(height:15),




            // =====================
            // AI RECOMMENDATION
            // =====================


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


              child:const Row(

                children:[


                  Icon(

                    Icons.auto_awesome,

                    color:navy,

                  ),


                  SizedBox(width:12),



                  Expanded(

                    child:Text(

                      "Rekomendasi AI: Fokuskan pembelajaran pada modul yang memiliki nilai kompetensi rendah.",

                      style:
                      TextStyle(

                        color:navy,

                        fontSize:12,

                        height:1.5,

                      ),

                    ),

                  )


                ],

              ),

            ),




            const SizedBox(height:20),




            // =====================
            // EXPORT BUTTON
            // =====================


            SizedBox(

              height:55,

              child:
              ElevatedButton.icon(

                onPressed:(){

                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(

                      content:
                      Text(
                        "Export RPL/LSP belum terhubung",
                      ),

                    ),

                  );

                },


                icon:
                const Icon(
                  Icons.download_rounded,
                ),


                label:
                const Text(
                  "Export ke RPL/LSP",
                ),


                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  navy,

                  foregroundColor:
                  Colors.white,


                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(16),

                  ),

                ),

              ),

            )



          ],

        ),

      ),

    );


  }

}