import 'dart:convert';

import 'package:grade/grade.dart';
import 'package:http/http.dart' as http;

import 'api_do_github.dart';

/// Adaptador da consulta pública: lê o grade.json que o GitHub publicou junto com o site, já conferido. Não
/// precisa de token e não escreve nada; quem escreve é o painel, pelo repositório.
class RepositorioGradePublicado implements RepositorioGrade {
  RepositorioGradePublicado({required this.endereco, http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final Uri endereco;
  final http.Client _cliente;

  @override
  Future<Grade?> gradeAtual() async {
    final resposta = await _cliente.get(endereco.replace(queryParameters: semCache()));
    if (resposta.statusCode == 404) return null;
    if (resposta.statusCode != 200) {
      throw http.ClientException('O site respondeu ${resposta.statusCode} para a grade', endereco);
    }
    return gradeDoJson(utf8.decode(resposta.bodyBytes));
  }

  @override
  Future<void> substituir(Grade grade) =>
      throw UnsupportedError('A consulta pública só lê a grade; quem publica é o painel.');
}
