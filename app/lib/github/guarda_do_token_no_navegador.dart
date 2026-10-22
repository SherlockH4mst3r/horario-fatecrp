import 'package:web/web.dart';

import 'guarda_do_token_base.dart';

/// No navegador, o token fica no sessionStorage: vale para a aba até ela fechar, e não passa para outras abas.
GuardaDoToken guardaDaAba() => _GuardaNoSessionStorage();

class _GuardaNoSessionStorage implements GuardaDoToken {
  static const _chave = 'token-do-github';

  @override
  Future<String?> lido() async {
    try {
      return window.sessionStorage.getItem(_chave);
    } catch (_) {
      return null; // Armazenamento bloqueado: o admin cola o token de novo.
    }
  }

  @override
  Future<void> guardar(String token) async {
    try {
      window.sessionStorage.setItem(_chave, token);
    } catch (_) {
      // Armazenamento bloqueado: o token vale só até recarregar a página.
    }
  }

  @override
  Future<void> apagar() async {
    try {
      window.sessionStorage.removeItem(_chave);
    } catch (_) {}
  }
}
