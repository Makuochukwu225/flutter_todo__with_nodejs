import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity_x/velocity_x.dart';

import 'config.dart';

class Dashboard extends StatefulWidget {
  final token;
  const Dashboard({@required this.token, Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late String userId;
  TextEditingController _todoTitle = TextEditingController();
  TextEditingController _todoDesc = TextEditingController();
  List? items;
  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);

    userId = jwtDecodedToken['_id'];
    getTodoList(userId);
  }

  void addTodo() async {
    if (_todoTitle.text.isNotEmpty && _todoDesc.text.isNotEmpty) {
      var regBody = {
        "userId": userId,
        "title": _todoTitle.text,
        "desc": _todoDesc.text
      };

      var response = await http.post(Uri.parse(addtodo),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(regBody));

      var jsonResponse = jsonDecode(response.body);

      print(response.body);

      print(jsonResponse['status']);

      if (jsonResponse['status']) {
        _todoDesc.clear();
        _todoTitle.clear();
        Navigator.pop(context);
        getTodoList(userId);
      } else {
        print("SomeThing Went Wrong");
      }
    }
  }

  void getTodoList(userId) async {
    var regBody = {"userId": userId};

    var response = await http.post(Uri.parse(getToDoList),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody));
    print(response.body);

    var jsonResponse = jsonDecode(response.body);
    items = jsonResponse['success'];

    setState(() {});
  }

  void deleteItem(id) async {
    var regBody = {"id": id};

    var response = await http.post(Uri.parse(deleteTodo),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody));

    print(response.body);

    var jsonResponse = jsonDecode(response.body);
    if (jsonResponse['status']) {
      getTodoList(userId);
    }
  }

  void editItem(id) async {
    var regBody = {
      'id': id,
      'title': _todoTitle.text,
      'desc': _todoDesc.text,
    };

    var response = await http.patch(Uri.parse(updateTodo),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody));

    print(response.body);

    var jsonResponse = jsonDecode(response.body);
    if (jsonResponse['status']) {
      getTodoList(userId);
      _todoDesc.clear();
      _todoTitle.clear();
      Navigator.pop(context);
    }
  }

  void editUser() async {
    var pref = await SharedPreferences.getInstance();
    var token = pref.getString('token') ?? "";
    var id = JwtDecoder.decode(token)['_id'];
    var regBody = {
      'id': id,
      'name': "collins ogbodo",
      'avatar': "_todoDesc.text",
    };

    var response = await http.patch(Uri.parse(updateUser),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody));

    print(response.body);

    var jsonResponse = jsonDecode(response.body);
    if (jsonResponse['status']) {
      _todoDesc.clear();
      _todoTitle.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(
                top: 60.0, left: 30.0, right: 30.0, bottom: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        editUser();
                      },
                      child: CircleAvatar(
                        child: Icon(
                          Icons.list,
                          size: 30.0,
                        ),
                        backgroundColor: Colors.white,
                        radius: 30.0,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await SharedPreferences.getInstance().then((value) {
                          value.clear();
                        });
                      },
                      child: CircleAvatar(
                        child: Icon(
                          Icons.logout,
                          size: 30.0,
                        ),
                        backgroundColor: Colors.white,
                        radius: 30.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                Text(
                  'ToDo with NodeJS + Mongodb',
                  style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8.0),
                Text(
                  '5 Task',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: items == null
                    ? null
                    : ListView.builder(
                        itemCount: items!.length,
                        itemBuilder: (context, int index) {
                          return Slidable(
                            key: const ValueKey(0),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              dismissible: DismissiblePane(onDismissed: () {
                                // deleteItem(items![index]['_id']);
                              }),
                              children: [
                                SlidableAction(
                                  backgroundColor:
                                      Color.fromARGB(255, 88, 73, 254),
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Edit',
                                  onPressed: (BuildContext context) {
                                    print('${items![index]['_id']}');
                                    _todoDesc.text =
                                        items![index]['description'];
                                    _todoTitle.text = items![index]['title'];
                                    _displayEditTextInputDialog(
                                      context,
                                      items![index]['_id'],
                                    );
                                    // editItem('${items![index]['_id']}');
                                  },
                                ),
                                SlidableAction(
                                  backgroundColor: Color(0xFFFE4A49),
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                  onPressed: (BuildContext context) {
                                    print('${items![index]['_id']}');
                                    deleteItem('${items![index]['_id']}');
                                  },
                                ),
                              ],
                            ),
                            child: Card(
                              borderOnForeground: false,
                              child: ListTile(
                                leading: Icon(Icons.task),
                                title: Text('${items![index]['title']}'),
                                subtitle:
                                    Text('${items![index]['description']}'),
                                trailing: Icon(Icons.arrow_back),
                              ),
                            ),
                          );
                        }),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayTextInputDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Add-ToDo',
      ),
    );
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text('Add To-Do'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _todoTitle,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Title",
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)))),
                  ).p4().px8(),
                  TextField(
                    controller: _todoDesc,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Description",
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)))),
                  ).p4().px8(),
                  ElevatedButton(
                      onPressed: () {
                        addTodo();
                      },
                      child: Text("Add"))
                ],
              ));
        });
  }

  Future<void> _displayEditTextInputDialog(
      BuildContext context, String id) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text('Edit To-Do'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _todoTitle,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Title",
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)))),
                  ).p4().px8(),
                  TextField(
                    controller: _todoDesc,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Description",
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)))),
                  ).p4().px8(),
                  ElevatedButton(
                      onPressed: () {
                        editItem(id);
                      },
                      child: Text("Add"))
                ],
              ));
        });
  }
}
