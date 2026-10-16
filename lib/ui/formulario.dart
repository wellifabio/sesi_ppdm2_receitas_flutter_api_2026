import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import 'home.dart';
import 'splash.dart';

class Formulario extends StatefulWidget {
  const Formulario({super.key, this.id});

  final int? id;

  @override
  State<Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<Formulario> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _ingredientesController = TextEditingController();
  final TextEditingController _modoFazerController = TextEditingController();
  final TextEditingController _imgController = TextEditingController();
  final TextEditingController _custoController = TextEditingController();
  String tipo = 'SALGADA';
  static const List<String> _tipos = ['DOCE', 'SALGADA', 'BEBIDA'];
  int _tabIndice = 2;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) carregarReceita();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _ingredientesController.dispose();
    _modoFazerController.dispose();
    _imgController.dispose();
    _custoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.id == null
            ? Text('Nova receita')
            : Text('Editar da receita'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(18.0),
          child: SizedBox(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  TextField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      hintText: 'Nome da receita',
                      labelText: 'Nome da receita:',
                    ),
                  ),
                  DropdownButton<String>(
                    value: tipo,
                    hint: Text('Selecione o tipo'),
                    isExpanded: true,
                    items: _tipos.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (String? novoValor) {
                      if (novoValor == null) return;
                      setState(() {
                        tipo = novoValor;
                      });
                    },
                  ),
                  TextField(
                    controller: _ingredientesController,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Ingredientes',
                      labelText: 'Ingredientes:',
                    ),
                  ),
                  TextField(
                    controller: _modoFazerController,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Modo de fazer',
                      labelText: 'Modo de fazer:',
                    ),
                  ),
                  TextField(
                    controller: _imgController,
                    decoration: InputDecoration(
                      hintText: 'URL da imagem',
                      labelText: 'URL da imagem:',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Image.network(
                    _imgController.text,
                    width: 200,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 200),
                  ),
                  TextField(
                    controller: _custoController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Custo R\$ aproximado',
                      labelText: 'Custo R\$ aproximado:',
                    ),
                  ),
                  widget.id == null
                      ? ElevatedButton(
                          onPressed: enviarReceita,
                          child: Text('Registrar Receita'),
                        )
                      : ElevatedButton(
                          onPressed: alterarReceita,
                          child: Text('Alterar Receita'),
                        ),
                ],
              ),
            ),
          ),
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
          if (indice == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home()),
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

  Future<void> carregarReceita() async {
    try {
      final url = Uri.parse(Api.getEndPoint('receitas/${widget.id}'));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          final receita = Map<String, dynamic>.from(data);
          final custo = receita['custoAproximado'];
          final custoCarregado = custo is num
              ? custo.toDouble()
              : double.tryParse(custo?.toString() ?? '') ?? 0.0;
          if (!mounted) return;
          setState(() {
            _nomeController.text = receita['nome']?.toString() ?? '';
            final tipoCarregado = receita['tipo']?.toString();
            tipo = _tipos.contains(tipoCarregado)
                ? tipoCarregado!
                : _tipos.first;
            _ingredientesController.text =
                receita['ingredientes']?.toString() ?? '';
            _modoFazerController.text = receita['modoFazer']?.toString() ?? '';
            _imgController.text = receita['img']?.toString() ?? '';
            _custoController.text = custoCarregado == 0
                ? ''
                : custoCarregado.toString();
          });
          return;
        }
      }
      _mostrarMensagem('Não foi possível carregar esta receita.');
    } catch (_) {
      _mostrarMensagem('Erro ao se comunicar com a API!');
    }
  }

  Future<void> enviarReceita() async {
    final nome = _nomeController.text.trim();
    final ingredientes = _ingredientesController.text.trim();
    final modoFazer = _modoFazerController.text.trim();
    final img = _imgController.text.trim();
    final custo = double.tryParse(
      _custoController.text.trim().replaceAll(',', '.'),
    );

    if (nome.isEmpty ||
        ingredientes.isEmpty ||
        modoFazer.isEmpty ||
        custo == null ||
        custo == 0) {
      _mostrarMensagem('Preencha todos os campos obrigatórios');
      return;
    }

    final dados = <String, dynamic>{
      'nome': nome,
      'tipo': tipo,
      'ingredientes': ingredientes,
      'modoFazer': modoFazer,
      if (img.isNotEmpty) 'img': img,
      'custoAproximado': custo,
    };

    try {
      final url = Uri.parse(Api.getEndPoint('receitas'));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 201 && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Splash()),
        );
      } else {
        _mostrarMensagem('Erro ao registar receita na API');
      }
    } catch (_) {
      _mostrarMensagem('Erro ao se comunicar com a API');
    }
  }

  Future<void> alterarReceita() async {
    final nome = _nomeController.text.trim();
    final ingredientes = _ingredientesController.text.trim();
    final modoFazer = _modoFazerController.text.trim();
    final img = _imgController.text.trim();
    final custo = double.tryParse(
      _custoController.text.trim().replaceAll(',', '.'),
    );

    if (nome.isEmpty ||
        ingredientes.isEmpty ||
        modoFazer.isEmpty ||
        custo == null ||
        custo == 0) {
      _mostrarMensagem('Preencha todos os campos obrigatórios');
      return;
    }

    final dados = <String, dynamic>{
      'nome': nome,
      'tipo': tipo,
      'ingredientes': ingredientes,
      'modoFazer': modoFazer,
      if (img.isNotEmpty) 'img': img,
      'custoAproximado': custo,
    };

    try {
      final url = Uri.parse(Api.getEndPoint('receitas/${widget.id}'));
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 202 && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Splash()),
        );
      } else {
        _mostrarMensagem('Erro ao alterar receita na API');
      }
    } catch (_) {
      _mostrarMensagem('Erro ao se comunicar com a API');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), duration: const Duration(seconds: 2)),
    );
  }
}
