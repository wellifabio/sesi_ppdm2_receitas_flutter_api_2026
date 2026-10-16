import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import '../root/file.dart';
import '../widget/aleatoria.dart';
import 'formulario.dart';
import 'splash.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<dynamic> receitas = [];
  List<dynamic> filtradas = [];
  List<String> curtidas = [];
  bool _carregando = true;
  int _tabIndice = 1;
  String _filtroNome = '';
  String? _filtroTipo;
  bool _somenteFavoritas = false;

  @override
  void initState() {
    super.initState();
    carregarReceitas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receitas'),
        actions: [
          TextButton.icon(
            onPressed: _carregando || receitas.isEmpty ? null : _criarWidget,
            label: Text(
              'Criar Widget',
              style: TextStyle(
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 2.0),
                    blurRadius: 3.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            icon: Icon(Icons.add_to_home_screen),
          ),
        ],
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : receitas.isEmpty
          ? Center(child: Text('Nenhuma receita encontrada'))
          : Padding(
              padding: EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 12,
                children: [
                  TextField(
                    decoration: InputDecoration(hintText: 'Filtro'),
                    onChanged: filtroNome,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 12,
                      children: [
                        ElevatedButton(
                          onPressed: () => filtroTipo(null),
                          child: Text("TODAS"),
                        ),
                        ElevatedButton(
                          onPressed: () => filtroTipo("DOCE"),
                          child: Text("DOCE"),
                        ),
                        ElevatedButton(
                          onPressed: () => filtroTipo("SALGADA"),
                          child: Text("SALGADA"),
                        ),
                        ElevatedButton(
                          onPressed: () => filtroTipo("BEBIDA"),
                          child: Text("BEBIDA"),
                        ),
                        ElevatedButton(
                          onPressed: () => filtroFavoritas(!_somenteFavoritas),
                          child: Text("FAVORITAS"),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.all(12),
                      itemCount: filtradas.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtradas[index] as Map<String, dynamic>;
                        final nome = item['nome']?.toString() ?? 'Receita';
                        final img = item['img']?.toString() ?? '';
                        final int id = item['id'] ?? 0;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          onTap: () => detalhes(id),
                          leading: SizedBox(
                            width: 56,
                            height: 56,
                            child: img.isNotEmpty && img != ''
                                ? Image.network(
                                    img,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) => Icon(Icons.image_not_supported),
                                  )
                                : Icon(Icons.restaurant, size: 32),
                          ),
                          title: Text(nome),
                          trailing: SizedBox(
                            width: 80,
                            child: Row(
                              spacing: 20,
                              children: [
                                GestureDetector(
                                  onTap: () => curtir(item['id']),
                                  child: Icon(
                                    item['like'] == true
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => confirmaExcluir(item['id']),
                                  child: Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndice,
        onTap: (indice) {
          setState(() {
            _tabIndice = indice;
          });
          if (indice == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Splash()),
            );
          }
          if (indice == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Formulario()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Splash'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Nova'),
        ],
      ),
    );
  }

  Future<void> carregarReceitas() async {
    setState(() {
      _carregando = true;
    });
    await carregarCurtidas();
    try {
      final url = Uri.parse(Api.getEndPoint('receitas'));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            receitas = data;
          });
          relacionarFavoritas();
          return;
        }
      }
      setState(() {
        receitas = [];
      });
    } catch (_) {
      setState(() {
        receitas = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao se comunicar com a API! Necessário acesso a internet.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void detalhes(int id) {
    final receita = receitas.firstWhere(
      (item) => item is Map && item['id'] == id,
      orElse: () => null,
    );
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(receita["nome"]),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                spacing: 12,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: receita["img"] != null
                        ? Image.network(
                            receita["img"],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image_not_supported),
                          )
                        : Icon(Icons.restaurant, size: 32),
                  ),
                  Text('Ingredientes: ${receita["ingredientes"]}'),
                  Text('Modo de fazer: ${receita["modoFazer"]}'),
                  Text(
                    'Custo aproximado: R\$ ${receita["custoAproximado"].toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Editar'),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Formulario(id: id)),
              ),
            ),
          ],
        ),
      );
    }
  }

  void confirmaExcluir(int id) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Confirma exclusão"),
          content: Text('Deseja realmente excluir a receita número: $id'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirmar'),
              onPressed: () {
                Navigator.of(context).pop();
                excluirReceita(id);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> excluirReceita(int id) async {
    try {
      final url = Uri.parse(Api.getEndPoint('receitas/$id'));
      final response = await http.delete(url);
      if (response.statusCode == 204) {
        carregarReceitas();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir receita!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao se comunicar com a API!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void filtroNome(String? nome) {
    _filtroNome = nome?.trim() ?? '';
    _aplicarFiltros();
  }

  void filtroTipo(String? tipo) {
    _filtroTipo = tipo;
    _aplicarFiltros();
  }

  void filtroFavoritas(bool somenteFavoritas) {
    _somenteFavoritas = somenteFavoritas;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final nomeBusca = _filtroNome.toLowerCase();
    setState(() {
      filtradas = receitas.where((receita) {
        if (receita is! Map) return false;
        final nome = receita['nome']?.toString().toLowerCase() ?? '';
        final tipo = receita['tipo']?.toString().toUpperCase();
        return nome.contains(nomeBusca) &&
            (_filtroTipo == null || tipo == _filtroTipo) &&
            (!_somenteFavoritas || receita['like'] == true);
      }).toList();
    });
  }

  void relacionarFavoritas() {
    for (var item in receitas) {
      if (item is Map) {
        item['like'] = curtidas.contains(item['id']?.toString());
      }
    }
    _aplicarFiltros();
  }

  Future<void> curtir(int id) async {
    final idReceita = id.toString();
    if (curtidas.contains(idReceita)) {
      curtidas.remove(idReceita);
    } else {
      curtidas.add(idReceita);
    }
    for (final item in receitas) {
      if (item is Map && item['id']?.toString() == idReceita) {
        item['like'] = curtidas.contains(idReceita);
      }
    }
    _aplicarFiltros();
    await salvarDados();
  }

  Future<void> carregarCurtidas() async {
    final linhas = (await GerenciarArquivo.abrir())
        .split('\n')
        .where((linha) => linha.isNotEmpty)
        .toSet()
        .toList();
    setState(() {
      curtidas = linhas;
    });
  }

  Future<void> salvarDados() async {
    final conteudo = curtidas.join('\n');
    await GerenciarArquivo.salvar(conteudo);
  }

  Future<void> _criarWidget() async {
    try {
      await Aleatoria.criarWidget(receitas);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Widget de receita adicionado à tela inicial.')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível criar o widget: $erro')),
      );
    }
  }
}
