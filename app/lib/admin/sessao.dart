/// Porta da sessão do admin: só quem entrou escreve na grade.
abstract interface class Sessao {
  bool get ativa;

  /// Quem entrou, para o painel mostrar ("Conectado como ..."); `null` sem sessão.
  String? get quem;

  Future<ResultadoDaEntrada> entrar(String token);

  /// Volta à sessão guardada nesta aba, depois de recarregar a página; `null` sem sessão guardada.
  Future<ResultadoDaEntrada?> retomar();

  Future<void> sair();
}

sealed class ResultadoDaEntrada {
  const ResultadoDaEntrada();
}

class EntradaAceita extends ResultadoDaEntrada {
  const EntradaAceita(this.quem);

  final String quem;
}

/// O token não serve (errado, expirado, sem acesso): o admin precisa corrigir.
class EntradaRecusada extends ResultadoDaEntrada {
  const EntradaRecusada(this.motivo);

  final String motivo;
}

/// Não deu para conferir o token (rede, GitHub fora do ar): não é culpa do admin.
class EntradaFalhou extends ResultadoDaEntrada {
  const EntradaFalhou(this.motivo);

  final String motivo;
}
