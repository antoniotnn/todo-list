import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();

    _readData().then((value) {
      setState(() {
        _todoList = jsonDecode(value!);
      });
    });
  }

  final _toDoController = TextEditingController();

  List _todoList = [];

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  Future<void> _addToDo() async => setState(() {
    Map<String, dynamic> newToDo = {};
    newToDo["title"] = _toDoController.text;
    _toDoController.text = "";
    newToDo["ok"] = false;
    _todoList.add(newToDo);
    _saveData();
  });

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if(a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: const InputDecoration(
                        labelText: 'Nova Tarefa',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                ElevatedButton(
                  // style: ButtonStyle(
                  //   backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                  //   foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  // ),   // outra forma de fazer
                  style: ElevatedButton.styleFrom(
                      primary: Colors.blueAccent, //cor do botão
                      onPrimary: Colors.white //cor do texto do botão
                      ),
                  onPressed: _addToDo,
                  child: const Text('ADD'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: buildItem,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (bool? value) {
          setState(() {
            _todoList[index]["ok"] = value;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);

          _saveData();

          final snackBar = SnackBar(
            content: Text('Tarefa "${_lastRemoved["title"]}" removida!'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: const Duration(seconds: 4),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
