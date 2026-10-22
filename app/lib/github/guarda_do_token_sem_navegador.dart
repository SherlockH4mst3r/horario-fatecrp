import 'guarda_do_token_base.dart';

/// Fora do navegador, não há aba: o token fica na memória.
GuardaDoToken guardaDaAba() => GuardaDoTokenEmMemoria();
