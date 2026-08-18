import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dosen_dashboard_screen.dart'
    show MahasiswaKompetensi, dummyMahasiswaDosen;

import 'student_detail_screen.dart';


// ===============================
// COLOR STATUS
// ===============================

Color statusColor(String status) {

  switch(status){

    case 'Dikuasai':
      return const Color(0xFF0F414A);

    case 'Perlu Bantuan':
      return const Color(0xFFDBA98A);

    case 'Tertinggal':
      return const Color(0xFF7F0303);

    default:
      return Colors.grey;
  }

}



// ===============================
// SCREEN
// ===============================

class StudentListScreen extends ConsumerWidget {

  const StudentListScreen({super.key});


  static const cream =
  Color(0xFFEFE8DF);

  static const navy =
  Color(0xFF0F414A);



  @override
  Widget build(
      BuildContext context,
      WidgetRef ref
      ){

    final mahasiswa =
        dummyMahasiswaDosen;



    return Scaffold(

      backgroundColor: cream,


      body: SafeArea(

        child: Column(

          children:[



            // ======================
            // HEADER
            // ======================

            Padding(

              padding:
              const EdgeInsets.all(20),


              child:Row(

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

                        color:Colors.white,

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



                  const Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,


                    children:[


                      Text(

                        "Mahasiswa",

                        style:TextStyle(

                          fontSize:24,

                          fontWeight:
                          FontWeight.w800,

                          color:navy,

                        ),

                      ),


                      Text(

                        "Monitoring kompetensi kelas",

                        style:TextStyle(

                          color:Colors.black54,

                          fontSize:12,

                        ),

                      ),


                    ],

                  )


                ],

              ),

            ),




            // ======================
            // SEARCH
            // ======================


            Container(

              margin:
              const EdgeInsets.symmetric(
                  horizontal:20
              ),


              padding:
              const EdgeInsets.symmetric(
                  horizontal:15
              ),


              decoration:
              BoxDecoration(

                color:Colors.white,

                borderRadius:
                BorderRadius.circular(18),

              ),


              child:
              const TextField(

                decoration:

                InputDecoration(

                  hintText:
                  "Cari mahasiswa...",

                  border:
                  InputBorder.none,

                  icon:
                  Icon(
                    Icons.search,
                    color:navy,
                  ),

                ),

              ),

            ),



            const SizedBox(height:20),




            // ======================
            // LIST
            // ======================


            Expanded(

              child:ListView.builder(

                padding:
                const EdgeInsets.symmetric(
                    horizontal:20
                ),


                itemCount:
                mahasiswa.length,


                itemBuilder:
                    (context,index){


                  final mhs =
                  mahasiswa[index];



                  return GestureDetector(

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:(context)=>

                              StudentDetailScreen(

                                mahasiswa:mhs,

                              ),

                        ),

                      );

                    },


                    child:
                    _studentCard(mhs),

                  );


                },


              ),

            )


          ],

        ),

      ),

    );

  }






  // ===============================
  // STUDENT CARD
  // ===============================


  Widget _studentCard(
      MahasiswaKompetensi mhs
      ){

    return Container(

      margin:
      const EdgeInsets.only(
          bottom:14
      ),


      padding:
      const EdgeInsets.all(18),


      decoration:
      BoxDecoration(

          color:Colors.white,

          borderRadius:
          BorderRadius.circular(22),


          boxShadow:[

            BoxShadow(

              color:
              Colors.black.withOpacity(.04),

              blurRadius:15,

              offset:
              const Offset(0,5),

            )

          ]

      ),



      child:Row(

        children:[



          // Avatar

          Container(

            width:52,

            height:52,


            decoration:
            BoxDecoration(

              color:
              statusColor(
                  mhs.status
              ).withOpacity(.15),


              shape:
              BoxShape.circle,

            ),


            child:
            Icon(

              Icons.person,

              color:
              statusColor(
                  mhs.status
              ),

            ),

          ),



          const SizedBox(width:15),




          Expanded(

            child:Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,


              children:[


                Text(

                  mhs.nama,

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.w700,

                    fontSize:15,

                    color:
                    navy,

                  ),

                ),



                const SizedBox(height:4),



                Text(

                  mhs.mataKuliah,

                  style:
                  const TextStyle(

                    fontSize:12,

                    color:
                    Colors.black54,

                  ),

                ),



                const SizedBox(height:12),



                ClipRRect(

                  borderRadius:
                  BorderRadius.circular(20),


                  child:
                  LinearProgressIndicator(

                    minHeight:8,

                    value:
                    mhs.skor,


                    backgroundColor:
                    Colors.black12,


                    color:
                    statusColor(
                        mhs.status
                    ),

                  ),

                )


              ],

            ),

          ),




          const SizedBox(width:12),




          Column(

            children:[


              Text(

                "${(mhs.skor*100).toInt()}%",

                style:
                const TextStyle(

                  fontWeight:
                  FontWeight.bold,

                  color:navy,

                  fontSize:18,

                ),

              ),



              const SizedBox(height:5),



              Container(

                padding:
                const EdgeInsets.symmetric(

                  horizontal:10,

                  vertical:5,

                ),


                decoration:
                BoxDecoration(

                  color:
                  statusColor(
                      mhs.status
                  ),


                  borderRadius:
                  BorderRadius.circular(20),

                ),


                child:
                Text(

                  mhs.status,

                  style:
                  const TextStyle(

                    color:Colors.white,

                    fontSize:9,

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),

              )


            ],

          )



        ],

      ),

    );

  }


}