/// Porta da sessão do admin: só quem entrou escreve na grade. No ticket 10 ela passa a ser o login do Supabase.
abstract interface class Sessao {
  bool get ativa;

  /// Devolve `false` quando o e-mail ou a senha não conferem.
  Future<bool> entrar({required String email, required String senha});

  Future<void> sair();
}

/// Sessão de mentira, para testar o painel sem banco: um único admin, com e-mail e senha fixos, e a sessão só
/// dura enquanto a página está aberta. Não protege nada; quem protege a grade de verdade é o Supabase (RLS).
class SessaoSimulada implements Sessao {
  SessaoSimulada({required String email, required String senha}) : _email = email.toLowerCase(), _senha = senha;

  final String _email;
  final String _senha;
  bool _ativa = false;

  @override
  bool get ativa => _ativa;

  @override
  Future<bool> entrar({required String email, required String senha}) async {
    _ativa = email.trim().toLowerCase() == _email && senha == _senha;
    return _ativa;
  }

  @override
  Future<void> sair() async => _ativa = false;
}
