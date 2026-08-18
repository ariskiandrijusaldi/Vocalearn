import 'package:flutter/material.dart';

import '../../models/materi_model.dart';



class MaterialDetailScreen
    extends StatelessWidget{


  final MateriModel materi;



  const MaterialDetailScreen({

    super.key,

    required this.materi

  });



  @override
  Widget build(BuildContext context){


    return Scaffold(

      appBar:
      AppBar(

        title:
        Text(
            materi.judul
        ),

      ),



      body:
      Padding(

        padding:
        const EdgeInsets.all(20),


        child:
        Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children:[



            const Icon(
              Icons.menu_book,
              size:70,
            ),



            const SizedBox(height:20),



            Text(

              materi.judul,

              style:
              const TextStyle(

                fontSize:24,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(height:10),



            Text(
                materi.deskripsi
            ),



            const SizedBox(height:20),



            Text(

                "File : ${materi.file}"

            ),



            const SizedBox(height:20),



            Container(

              padding:
              const EdgeInsets.all(15),

              color:
              Colors.blue.shade100,


              child:
              Text(

                  "Status AI : ${materi.statusAI}"

              ),

            )



          ],

        ),

      ),


    );


  }


}