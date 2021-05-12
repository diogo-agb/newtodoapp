import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _todoList = [];
  final TextEditingController _todoController = TextEditingController();

  //Para guardar o index do último registro removido
  int _indexLastRemoved;

  //Para guardar o último registro removido
  Map<String, dynamic> _lastRemoved;

  @override
  void initState() {
    //Carrega os dados do arquivo na inicialização da classe
    _lerDados().then((value) {
      setState(() {
        _todoList = json.decode(value);
      });
    });
    super.initState();
  }

  Future<String> _lerDados() async {
    try {
      final arquivo = await _abreArquivo();
      return arquivo.readAsString();
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<File> _abreArquivo() async {
    //Se não existir o arquivo, o mesmo será criado
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/dados.json');
  }

  Future<Null> _recarregaLista() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b) {
        if (a['realizado'] && !b['realizado']) {
          return 1;
        }
        if (!a['realizado'] && b['realizado']) {
          return -1;
        }
        return 0;
      });
      _salvarDados();
    });
    return null;
  }

  Future<File> _salvarDados() async {
    String dados = json.encode(_todoList);
    final arquivo = await _abreArquivo();
    return arquivo.writeAsString(dados);
  }

  void adicionaTarefa() {
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      novaTarefa['titulo'] = _todoController.text;
      novaTarefa['realizado'] = false;
      _todoController.text = '';
      _todoList.add(novaTarefa);
      _salvarDados();
    });
  }

  Widget widgetTarefa(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red, //Cor de fundo quando for apagar a mensagem
        child: Align(
          alignment: Alignment(0.85, 0.0),
          child: Icon(
            Icons.delete_sweep_outlined,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.endToStart,
      child: CheckboxListTile(
        onChanged: (value) {
          setState(() {
            _todoList[index]['realizado'] = value;
            _salvarDados();
          });
        },
        title: Text(
          _todoList[index]['titulo'],
        ),
        value: _todoList[index]['realizado'],
        secondary: CircleAvatar(
          child: Icon(
            _todoList[index]['realizado'] ? Icons.check : Icons.error,
            color: Theme.of(context).iconTheme.color,
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        checkColor: Theme.of(context).primaryColor,
        activeColor: Theme.of(context).secondaryHeaderColor,
      ), //Até aqui controlamos o estado da lista

      //Fazendo uma exclusão dentro de um determinado tempo
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          print('LAST REMOVED $_lastRemoved');
          _indexLastRemoved = index;
          _todoList.removeAt(index);
          _salvarDados();
        });
        final snack = SnackBar(
          content: Text('Tarefa ${_lastRemoved["titulo"]} apagada!'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              setState(() {
                _todoList.insert(_indexLastRemoved, _lastRemoved);
                _salvarDados();
              });
            },
          ),
          duration: Duration(seconds: 5),
        );
        //Configurar : mopstrar/esconder o desfazer
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(snack);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) => Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _todoController,
                    maxLength: 50,
                    decoration: InputDecoration(labelText: "Nova tarefa"),
                  )),
                  Container(
                    height: 45.0,
                    width: 45.0,
                    child: FloatingActionButton(
                      child: Icon(Icons.save),
                      onPressed: () {
                        if (_todoController.text.isEmpty) {
                          final alerta = SnackBar(
                            content: Text('Não pode ser vazia!'),
                            duration: Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'Ok',
                              onPressed: () {
                                //Scaffold.of(context).removeCurrentSnackBar();
                                ScaffoldMessenger.of(context)
                                    .removeCurrentSnackBar();
                              },
                            ),
                          );

                          //Scaffold.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          //Scaffold.of(context).showSnackBar(alerta);
                          ScaffoldMessenger.of(context).showSnackBar(alerta);
                        } else {
                          adicionaTarefa();
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
            Padding(padding: (EdgeInsets.only(top: 10.0))),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _recarregaLista,
                child: ListView.builder(
                  itemBuilder: widgetTarefa,
                  itemCount: _todoList.length,
                  padding: EdgeInsets.only(top: 10.0),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
