import 'package:grade_app/admin/sessao.dart';

/// Sessão falsa para os testes do painel: aceita um token fixo, sem falar com o GitHub.
class SessaoDeTeste implements Sessao {
  SessaoDeTeste({required this.tokenAceito});

  final String tokenAceito;
  bool _ativa = false;

  @override
  bool get ativa => _ativa;

  @override
  String? get quem => _ativa ? 'Admin de teste' : null;

  @override
  Future<ResultadoDaEntrada> entrar(String token) async {
    _ativa = token.trim() == tokenAceito;
    return _ativa ? EntradaAceita(quem!) : const EntradaRecusada('Token incorreto.');
  }

  @override
  Future<ResultadoDaEntrada?> retomar() async => null;

  @override
  Future<void> sair() async => _ativa = false;
}
