import 'dart:convert';

import 'package:http/http.dart' as http;

import '../admin/sessao.dart';
import 'api_do_github.dart';
import 'guarda_do_token.dart';

/// Sessão do admin pelo token do GitHub: entra quem tem um token com acesso de escrita ao repositório da grade.
///
/// O site não guarda senha nenhuma. Quem decide quem é admin é o GitHub (quem pode escrever no repositório), e
/// é ele que recusa uma gravação sem permissão, mesmo que alguém contorne o painel.
class SessaoNoGitHub implements Sessao {
  SessaoNoGitHub({required this.repositorio, required GuardaDoToken guarda, http.Client? cliente})
    : _guarda = guarda,
      _cliente = cliente ?? http.Client();

  /// Como "dono/nome".
  final String repositorio;

  /// Só o nome do repositório, para as mensagens: o site pode ser de qualquer conta ou organização.
  String get _nome => repositorio.split('/').last;
  final GuardaDoToken _guarda;
  final http.Client _cliente;
  String? _token;
  String? _quem;

  @override
  bool get ativa => _token != null;

  @override
  String? get quem => _quem;

  /// O token da sessão, para gravar no repositório; `null` sem sessão.
  String? get token => _token;

  @override
  Future<ResultadoDaEntrada> entrar(String token) async {
    final limpo = token.trim();
    final resultado = await _conferir(limpo);
    if (resultado case EntradaAceita(:final quem)) {
      _token = limpo;
      _quem = quem;
      await _guarda.guardar(limpo);
    }
    return resultado;
  }

  @override
  Future<ResultadoDaEntrada?> retomar() async {
    final guardado = await _guarda.lido();
    if (guardado == null) return null;
    final resultado = await entrar(guardado);
    if (resultado is EntradaRecusada) await _guarda.apagar();
    return resultado;
  }

  @override
  Future<void> sair() async {
    _token = null;
    _quem = null;
    await _guarda.apagar();
  }

  Future<ResultadoDaEntrada> _conferir(String token) async {
    try {
      final acesso = await _cliente.get(
        apiDoGitHub.replace(path: '/repos/$repositorio', queryParameters: semCache()),
        headers: cabecalhosDoGitHub(token),
      );
      switch (acesso.statusCode) {
        case 401:
          return const EntradaRecusada(
            'O GitHub não reconheceu o token. Confira se ele foi copiado inteiro e se não expirou.',
          );
        case 403 || 404:
          return EntradaRecusada('O token não dá acesso ao repositório $_nome. Gere um token para ele.');
        case 200:
          break;
        default:
          return EntradaFalhou('O GitHub não respondeu (código ${acesso.statusCode}). Tente de novo em instantes.');
      }
      final podeEscrever = switch (jsonDecode(acesso.body)) {
        {'permissions': {'push': true}} => true,
        _ => false,
      };
      if (!podeEscrever) {
        return EntradaRecusada(
          'Esta conta não pode escrever no repositório $_nome; peça acesso a quem administra o site.',
        );
      }
      final usuario = await _cliente.get(
        apiDoGitHub.replace(path: '/user', queryParameters: semCache()),
        headers: cabecalhosDoGitHub(token),
      );
      final quem = switch (jsonDecode(usuario.body)) {
        {'login': String login} => login,
        _ => 'admin',
      };
      return EntradaAceita(quem);
    } on Exception {
      return const EntradaFalhou('Não deu para falar com o GitHub. Confira a internet e tente de novo.');
    }
  }
}
