import 'dart:convert';

import 'package:grade/grade.dart';
import 'package:http/http.dart' as http;

import '../problema_para_o_admin.dart';
import 'api_do_github.dart';

/// A grade mudou no repositório desde que o painel a leu (outro admin publicou, por exemplo).
class GradeMudouNoGitHub implements ProblemaParaOAdmin {
  @override
  String get explicacao =>
      'A grade mudou no GitHub desde que o painel a leu (outro admin publicou?). '
      'Recarregue a página e tente de novo.';
}

/// O token não pode mais gravar no repositório (expirou ou perdeu a permissão).
class SemPermissaoNoGitHub implements ProblemaParaOAdmin {
  @override
  String get explicacao =>
      'O token não pode gravar no repositório: ele expirou ou não tem "Contents: Read and write". '
      'Saia e entre com um token novo.';
}

/// Adaptador do painel: a grade é um arquivo JSON no repositório do GitHub, e publicar é gravar um commit nele.
/// Depois do commit, o GitHub confere a grade e publica o site de novo.
class RepositorioGradeNoGitHub implements RepositorioGrade {
  RepositorioGradeNoGitHub({
    required this.repositorio,
    required this.caminho,
    required String? Function() token,
    this.ramo = 'main',
    http.Client? cliente,
  }) : _token = token,
       _cliente = cliente ?? http.Client();

  /// Como "dono/nome".
  final String repositorio;

  /// O arquivo da grade no repositório.
  final String caminho;
  final String ramo;
  final String? Function() _token;
  final http.Client _cliente;

  /// A versão do arquivo lida por último: o GitHub só aceita gravar por cima dela, e recusa se ela mudou.
  String? _versao;

  Uri get _arquivo => apiDoGitHub.replace(path: '/repos/$repositorio/contents/$caminho');

  Map<String, String> get _cabecalhos =>
      cabecalhosDoGitHub(_token() ?? (throw StateError('Sem sessão: entre com o token antes.')));

  @override
  Future<Grade?> gradeAtual() async {
    final resposta = await _cliente.get(
      _arquivo.replace(queryParameters: {'ref': ramo, ...semCache()}),
      headers: _cabecalhos,
    );
    if (resposta.statusCode == 404) {
      _versao = null;
      return null;
    }
    _conferir(resposta);
    if (jsonDecode(resposta.body) case {'sha': String versao, 'content': String conteudo}) {
      _versao = versao;
      return gradeDoJson(utf8.decode(base64.decode(conteudo.replaceAll(RegExp(r'\s'), ''))));
    }
    throw FormatException('O GitHub devolveu $caminho fora do formato esperado');
  }

  @override
  Future<void> substituir(Grade grade) async {
    final resposta = await _cliente.put(
      _arquivo,
      headers: _cabecalhos,
      body: jsonEncode({
        'message': 'Publica a grade ${grade.semestreLetivo.rotulo} pelo painel',
        'content': base64.encode(utf8.encode(gradeComoJson(grade))),
        'branch': ramo,
        'sha': ?_versao,
      }),
    );
    if (resposta.statusCode == 409 || resposta.statusCode == 422) throw GradeMudouNoGitHub();
    _conferir(resposta);
    if (jsonDecode(resposta.body) case {'content': {'sha': String versao}}) _versao = versao;
  }

  void _conferir(http.Response resposta) {
    if (resposta.statusCode == 401 || resposta.statusCode == 403) throw SemPermissaoNoGitHub();
    if (resposta.statusCode >= 300) {
      throw http.ClientException('GitHub respondeu ${resposta.statusCode} para $caminho', resposta.request?.url);
    }
  }
}
