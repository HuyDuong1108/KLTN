import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_table.dart';
import 'flashcard_detail_admin.dart';

class FlashcardManagementPage extends StatefulWidget {
  const FlashcardManagementPage({super.key});

  @override
  State<FlashcardManagementPage> createState() =>
      _FlashcardManagementPageState();
}

class _FlashcardManagementPageState extends State<FlashcardManagementPage> {

  String search = "";

  @override
  Widget build(BuildContext context) {

    return Container(
      color: const Color(0xffF4F8FB),
      padding: const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Flashcard Management",
            style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),
          ),

          const SizedBox(height:20),

          /// SEARCH
          TextField(
            onChanged:(v){
              setState(() {
                search=v.toLowerCase();
              });
            },
            decoration:InputDecoration(
              hintText:"Search flashcard...",
              prefixIcon:const Icon(Icons.search),
              filled:true,
              fillColor:Colors.white,
              border:OutlineInputBorder(
                borderRadius:BorderRadius.circular(12),
                borderSide:BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height:25),

          /// TABLE
          Expanded(
            child:StreamBuilder<QuerySnapshot>(

              stream:FirebaseFirestore.instance
                  .collection("flashcard_sets")
                  .snapshots(),

              builder:(context,communitySnap){

                if(!communitySnap.hasData){
                  return const Center(child:CircularProgressIndicator());
                }

                final communitySets=communitySnap.data!.docs;

                return StreamBuilder<QuerySnapshot>(

                  stream:FirebaseFirestore.instance
                      .collectionGroup("userFlashcards")
                      .snapshots(),

                  builder:(context,userSnap){

                    if(!userSnap.hasData){
                      return const Center(child:CircularProgressIndicator());
                    }

                    final userSets=userSnap.data!.docs;

                    final all=[...communitySets,...userSets];

                    final filtered=all.where((doc){

                      final data=doc.data() as Map<String,dynamic>;
                      final title=(data["title"]??"").toLowerCase();

                      return title.contains(search);

                    }).toList();

                    return AdminTable(

                      headers:const[
                        "Title",
                        "Description",
                        "Type",
                        "User",
                        "Words",
                        "Action"
                      ],

                      rows:filtered.map((doc){

                        final data=doc.data() as Map<String,dynamic>;

                        bool isCommunity=data["isCommunity"]==true;

                        final vocab=data["vocabList"]??[];

                        final userId = doc.reference.parent.parent?.id;

                        return [

                          InkWell(
                            child:Text(data["title"]??""),
                            onTap:(){

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:(_)=>FlashcardDetailAdminPage(
                                    setId:doc.id,
                                    data:data,
                                    isCommunity:isCommunity,
                                    userId:userId,
                                  ),
                                ),
                              );

                            },
                          ),

                          Text(data["description"]??""),

                          typeBadge(isCommunity?"community":"personal"),

                          Text(isCommunity?"-":userId??""),

                          Text("${vocab.length}"),

                          Row(
                            children:[

                              if(isCommunity)
                              IconButton(
                                icon:const Icon(Icons.edit,color:Colors.blue),
                                onPressed:(){},
                              ),

                              IconButton(
                                icon:const Icon(Icons.delete,color:Colors.red),
                                onPressed:() async{

                                  if(isCommunity){

                                    await FirebaseFirestore.instance
                                        .collection("flashcard_sets")
                                        .doc(doc.id)
                                        .delete();

                                  }else{

                                    await doc.reference.delete();

                                  }

                                },
                              )

                            ],
                          )

                        ];

                      }).toList(),

                    );

                  },

                );

              },

            ),
          )

        ],
      ),
    );

  }

  Widget typeBadge(String type){

    Color color = type=="community"
        ?const Color(0xFF4FC3F7)
        :const Color(0xFF81C784);

    return Container(
      padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
      decoration:BoxDecoration(
        color:color.withOpacity(0.2),
        borderRadius:BorderRadius.circular(20),
      ),
      child:Text(
        type,
        style:TextStyle(
          color:color,
          fontWeight:FontWeight.w600,
        ),
      ),
    );
  }
}