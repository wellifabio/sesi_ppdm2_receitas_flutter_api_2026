import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;

class Aleatoria {
  static const String _providerName = 'ReceitaWidgetProvider';

  static Future<void> criarWidget(List<dynamic> receitas) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'O widget da tela inicial está disponível no Android.',
      );
    }

    final receitasWidget = <Map<String, String>>[];
    for (var index = 0; index < receitas.length; index++) {
      final item = receitas[index];
      if (item is! Map) continue;

      final nome = item['nome']?.toString().trim() ?? '';
      if (nome.isEmpty) continue;

      var caminhoImagem = '';
      final urlImagem = item['img']?.toString() ?? '';
      final uriImagem = Uri.tryParse(urlImagem);
      if (uriImagem != null &&
          (uriImagem.scheme == 'http' || uriImagem.scheme == 'https')) {
        try {
          final resposta = await http
              .get(uriImagem)
              .timeout(const Duration(seconds: 10));
          if (resposta.statusCode == 200 && resposta.bodyBytes.isNotEmpty) {
            caminhoImagem = await HomeWidget.saveFile(
              'receita_widget_$index',
              resposta.bodyBytes,
              extension: 'img',
            );
          }
        } catch (_) {
          // A receita continua disponível no widget mesmo sem a imagem.
        }
      }

      receitasWidget.add({'nome': nome, 'imagem': caminhoImagem});
    }

    if (receitasWidget.isEmpty) {
      throw StateError('Nenhuma receita válida para criar o widget.');
    }

    await HomeWidget.saveWidgetData<String>(
      'receitas_widget',
      jsonEncode(receitasWidget),
    );
    await HomeWidget.updateWidget(androidName: _providerName);

    final suportaFixacao = await HomeWidget.isRequestPinWidgetSupported();
    if (suportaFixacao != true) {
      throw UnsupportedError(
        'Este launcher não permite adicionar widgets automaticamente.',
      );
    }
    await HomeWidget.requestPinWidget(androidName: _providerName);
  }
}
