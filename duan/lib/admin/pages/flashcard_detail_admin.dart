import 'package:flutter/material.dart';

class FlashcardDetailAdminPage extends StatelessWidget {

  final String setId;
  final Map<String,dynamic> data;
  final bool isCommunity;
  final String? userId;

  const FlashcardDetailAdminPage({
    super.key,
    required this.setId,
    required this.data,
    required this.isCommunity,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {

    final vocab=data["vocabList"]??[];

    return Scaffold(

      appBar:AppBar(
        title:Text(data["title"]??"Flashcard"),
      ),

      body:ListView.builder(

        padding:const EdgeInsets.all(20),

        itemCount:vocab.length,

        itemBuilder:(context,index){

          final v=vocab[index];

          return Card(

            child:ListTile(

              leading:CircleAvatar(
                child:Text("${index+1}"),
              ),

              title:Text(v["word"]??""),

              subtitle:Text(v["meaning"]??""),

              trailing:isCommunity
                  ?IconButton(
                      icon:const Icon(Icons.delete,color:Colors.red),
                      onPressed:(){},
                    )
                  :null,

            ),

          );

        },

      ),

    );

  }

}