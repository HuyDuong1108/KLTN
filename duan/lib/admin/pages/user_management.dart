import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_table.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {

  String searchText = "";
  int currentPage = 0;
  final int pageSize = 10;

  @override
  Widget build(BuildContext context) {

    return Container(
      color: const Color(0xffF4F8FB),
      padding: const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TITLE
          const Text(
            "User Management",
            style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),
          ),

          const SizedBox(height:20),

          /// STATISTICS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder:(context,snapshot){

              int total=0;
              int active=0;
              int premium=0;
              int newToday=0;

              if(snapshot.hasData){

                final users=snapshot.data!.docs;
                total=users.length;
                active=users.length;

                DateTime now=DateTime.now();

                for(var doc in users){

                  final data=doc.data() as Map<String,dynamic>;

                  if(data["role"]=="premium"){
                    premium++;
                  }

                  if(data["createdAt"]!=null){

                    Timestamp t=data["createdAt"];
                    DateTime created=t.toDate();

                    if(created.year==now.year &&
                        created.month==now.month &&
                        created.day==now.day){

                      newToday++;
                    }

                  }

                }

              }

              return Row(
                children:[

                  statCard("Total Users",total,const Color(0xFF4FC3F7)),
                  statCard("Active Users",active,const Color(0xFF81C784)),
                  statCard("Premium",premium,const Color(0xFFFFB74D)),
                  statCard("New Today",newToday,const Color(0xFFBA68C8)),

                ],
              );

            },
          ),

          const SizedBox(height:25),

          /// SEARCH
          TextField(
            onChanged:(v){
              setState(() {
                searchText=v.toLowerCase();
                currentPage=0;
              });
            },
            decoration:InputDecoration(
              hintText:"Search user...",
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
                  .collection("users")
                  .orderBy("createdAt",descending:true)
                  .snapshots(),

              builder:(context,snapshot){

                if(!snapshot.hasData){
                  return const Center(child:CircularProgressIndicator());
                }

                final filtered=snapshot.data!.docs.where((doc){

                  final data=doc.data() as Map<String,dynamic>;
                  final name=(data["name"]??"").toString().toLowerCase();

                  return name.contains(searchText);

                }).toList();


                int totalPages=(filtered.length/pageSize).ceil();

                int start=currentPage*pageSize;
                int end=start+pageSize;

                if(end>filtered.length) end=filtered.length;

                final pageUsers=filtered.sublist(start,end);


                return Column(
                  children:[

                    Expanded(
                      child:AdminTable(

                        headers:const[
                          "No",
                          "Name",
                          "Gender",
                          "Birthdate",
                          "Created",
                          "Action"
                        ],

                        rows:List.generate(pageUsers.length,(index){

                          final doc=pageUsers[index];
                          final data=doc.data() as Map<String,dynamic>;

                          String created="";

                          if(data["createdAt"]!=null){
                            Timestamp t=data["createdAt"];
                            created=t.toDate().toString().substring(0,10);
                          }

                          int stt=start+index+1;

                          return [

                            Text("$stt"),

                            Text(data["name"]??""),

                            Text(data["gender"]??""),

                            Text(data["birthdate"]??""),

                            Text(created),

                            Row(
                              children:[

                                IconButton(
                                  icon:const Icon(Icons.edit,color:Colors.blue),
                                  onPressed:(){
                                    editUser(doc.id,data);
                                  },
                                ),

                                IconButton(
                                  icon:const Icon(Icons.delete,color:Colors.red),
                                  onPressed:(){
                                    confirmDelete(doc.id);
                                  },
                                )

                              ],
                            )

                          ];

                        }),

                      ),
                    ),

                    const SizedBox(height:20),

                    /// PAGINATION
                    buildPagination(totalPages),

                  ],
                );

              },

            ),
          ),

        ],
      ),
    );

  }


  /// PAGINATION UI
  Widget buildPagination(int totalPages){

    return Row(
      mainAxisAlignment:MainAxisAlignment.center,
      children:List.generate(totalPages,(index){

        bool active=index==currentPage;

        return GestureDetector(

          onTap:(){
            setState(() {
              currentPage=index;
            });
          },

          child:Container(

            margin:const EdgeInsets.symmetric(horizontal:6),

            padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),

            decoration:BoxDecoration(

              color:active
                  ?const Color(0xFF4FC3F7)
                  :Colors.white,

              borderRadius:BorderRadius.circular(8),

              border:Border.all(
                color:active
                    ?const Color(0xFF4FC3F7)
                    :Colors.grey.shade300,
              ),

            ),

            child:Text(
              "${index+1}",
              style:TextStyle(
                color:active?Colors.white:Colors.black,
                fontWeight:FontWeight.bold,
              ),
            ),

          ),

        );

      }),
    );

  }


  /// DELETE CONFIRM
void confirmDelete(String uid) {

  showDialog(
    context: context,
    builder: (context) {

      return Dialog(
        backgroundColor: Colors.transparent,

        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// WARNING ICON
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 36,
                ),
              ),

              const SizedBox(height: 18),

              /// TITLE
              const Text(
                "Delete User",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              /// DESCRIPTION
              const Text(
                "Are you sure you want to delete this user?\nThis action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 26),

              /// BUTTONS
              Row(
                children: [

                  /// CANCEL
                  Expanded(
                    child: OutlinedButton(

                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      onPressed: () {
                        Navigator.pop(context);
                      },

                      child: const Text("Cancel", style: TextStyle(color: Colors.grey),),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// DELETE
                  Expanded(
                    child: ElevatedButton.icon(

                      icon: const Icon(Icons.delete,color: Colors.white,),

                      label: const Text("Delete", style: TextStyle(color: Colors.white),),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      onPressed: () async {

                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(uid)
                            .delete();

                        Navigator.pop(context);
                      },
                    ),
                  ),

                ],
              )

            ],
          ),
        ),
      );
    },
  );
}

  /// EDIT USER
 void editUser(String uid, Map<String, dynamic> data) {

  final nameController =
      TextEditingController(text: data["name"]);

  final birthController =
      TextEditingController(text: data["birthdate"]);

  String gender = data["gender"] ?? "Male";

  showDialog(
    context: context,
    builder: (context) {

      return Dialog(

        backgroundColor: Colors.transparent,

        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),

          child: StatefulBuilder(
            builder: (context, setState) {

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TITLE
                  const Text(
                    "Edit User",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Update user information",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  /// NAME
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: const Color(0xffF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// BIRTHDATE
                  TextField(
                    controller: birthController,
                    decoration: InputDecoration(
                      labelText: "Birthdate",
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      filled: true,
                      fillColor: const Color(0xffF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// GENDER
                  DropdownButtonFormField<String>(
                    value: gender,

                    decoration: InputDecoration(
                      labelText: "Gender",
                      prefixIcon: const Icon(Icons.wc),
                      filled: true,
                      fillColor: const Color(0xffF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),

                    items: const [

                      DropdownMenuItem(
                        value: "Male",
                        child: Text("Male"),
                      ),

                      DropdownMenuItem(
                        value: "Female",
                        child: Text("Female"),
                      ),

                    ],

                    onChanged: (value) {
                      setState(() {
                        gender = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  /// BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      /// CANCEL
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel", style: TextStyle(color: Colors.grey),),
                      ),

                      const SizedBox(width: 12),

                      /// SAVE
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text("Save Changes", style: TextStyle(color: Colors.white),),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC3F7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        onPressed: () async {

                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(uid)
                              .update({

                            "name": nameController.text.trim(),
                            "birthdate": birthController.text.trim(),
                            "gender": gender,

                          });

                          Navigator.pop(context);
                        },
                      )

                    ],
                  )

                ],
              );
            },
          ),
        ),
      );
    },
  );
}
  /// STAT CARD
  Widget statCard(String title,int value,Color color){

    return Expanded(
      child:Container(

        margin:const EdgeInsets.only(right:15),
        padding:const EdgeInsets.all(20),

        decoration:BoxDecoration(
          gradient:LinearGradient(
            colors:[color,color.withOpacity(0.7)],
          ),
          borderRadius:BorderRadius.circular(16),
        ),

        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[

            Text(
              title,
              style:const TextStyle(color:Colors.white70),
            ),

            const SizedBox(height:10),

            Text(
              "$value",
              style:const TextStyle(
                color:Colors.white,
                fontSize:24,
                fontWeight:FontWeight.bold,
              ),
            )

          ],
        ),
      ),
    );

  }

}