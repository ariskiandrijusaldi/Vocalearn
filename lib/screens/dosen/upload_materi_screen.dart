import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/materi_model.dart';
import '../../providers/materi_provider.dart';



class UploadMateriScreen
    extends ConsumerStatefulWidget{


  const UploadMateriScreen({super.key});


  @override
  ConsumerState<UploadMateriScreen> createState()
  =>_UploadMateriScreenState();


}




class _UploadMateriScreenState
    extends ConsumerState<UploadMateriScreen>{


  final judul =
  TextEditingController();


  final deskripsi =
  TextEditingController();



  String file =
      "Belum dipilih";




  void upload(){


    final data =
    MateriModel(

      id:
      DateTime.now()
          .toString(),

      judul:
      judul.text,

      deskripsi:
      deskripsi.text,

      file:
      file,

      statusAI:
      "Menunggu Analisis",

    );



    ref
        .read(materiProvider.notifier)
        .tambahMateri(data);



    Navigator.pop(context);



  }




  @override
  Widget build(BuildContext context){


    return Scaffold(

      backgroundColor:
      const Color(0xFFEFE8DF),


      appBar:
      AppBar(

        title:
        const Text(
            "Upload Materi"
        ),

        backgroundColor:
        const Color(0xFF0F414A),

      ),



      body:
      Padding(

        padding:
        const EdgeInsets.all(20),


        child:
        Column(

          children:[


            TextField(

              controller:
              judul,

              decoration:
              const InputDecoration(

                labelText:
                "Judul Materi",

                border:
                OutlineInputBorder(),

              ),

            ),



            const SizedBox(height:15),



            TextField(

              controller:
              deskripsi,

              maxLines:4,


              decoration:
              const InputDecoration(

                labelText:
                "Deskripsi",

                border:
                OutlineInputBorder(),

              ),

            ),



            const SizedBox(height:20),



            Container(

              padding:
              const EdgeInsets.all(20),

              width:
              double.infinity,

              decoration:
              BoxDecoration(

                color:
                Colors.white,

                borderRadius:
                BorderRadius.circular(15),

              ),


              child:
              Column(

                children:[


                  const Icon(
                    Icons.upload_file,
                    size:40,
                  ),


                  Text(file),



                  ElevatedButton(

                    onPressed: () async {

                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
                      );

                      if (result != null) {
                        setState(() {
                          file = result.files.single.name;
                        });
                      }

                    },

                    child:
                    const Text(
                        "Pilih File"
                    ),

                  )


                ],

              ),

            ),



            const Spacer(),



            SizedBox(

              width:
              double.infinity,

              child:
              ElevatedButton(

                onPressed:
                upload,


                child:
                const Text(
                    "Upload Materi"
                ),

              ),

            )



          ],

        ),

      ),


    );


  }


}