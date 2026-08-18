import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/materi_model.dart';



final materiProvider =
StateNotifierProvider<MateriNotifier,List<MateriModel>>(
        (ref){

      return MateriNotifier();

    });




class MateriNotifier
    extends StateNotifier<List<MateriModel>>{


  MateriNotifier()
      :
        super([


        MateriModel(

          id:"1",

          judul:
          "Dasar Flutter",

          deskripsi:
          "Pengenalan widget dan struktur aplikasi Flutter",

          file:
          "flutter.pdf",

          statusAI:
          "Belum dianalisis",

        ),


        MateriModel(

          id:"2",

          judul:
          "Pemrograman Dart",

          deskripsi:
          "Variabel, function dan class",

          file:
          "dart.pdf",

          statusAI:
          "Belum dianalisis",

        )


      ]);




  void tambahMateri(
      MateriModel materi
      ){

    state=[
      ...state,
      materi
    ];

  }


}