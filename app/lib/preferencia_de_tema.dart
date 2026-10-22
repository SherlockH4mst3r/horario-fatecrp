import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lembra o tema escolhido no botão do cabeçalho. Sem escolha, o site segue o tema do sistema.
abstract interface class PreferenciaDeTema {
  Future<ThemeMode> lida();

  Future<void> guardar(ThemeMode tema);
}

/// Guarda a escolha no navegador (localStorage, na web).
class PreferenciaDeTemaNoNavegador implements PreferenciaDeTema {
  static const _chave = 'tema';

  @override
  Future<ThemeMode> lida() async {
    try {
      final guardado = (await SharedPreferences.getInstance()).getString(_chave);
      return ThemeMode.values.asNameMap()[guardado] ?? ThemeMode.system;
    } catch (_) {
      return ThemeMode.system; // Armazenamento bloqueado: segue o sistema.
    }
  }

  @override
  Future<void> guardar(ThemeMode tema) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_chave, tema.name);
    } catch (_) {
      // Armazenamento bloqueado: o tema vale só até fechar a página.
    }
  }
}

/// Lembra a escolha só enquanto o programa roda. Serve aos testes.
class PreferenciaDeTemaEmMemoria implements PreferenciaDeTema {
  ThemeMode _tema = ThemeMode.system;

  @override
  Future<ThemeMode> lida() async => _tema;

  @override
  Future<void> guardar(ThemeMode tema) async => _tema = tema;
}

/// Dá às telas o tema em uso e o jeito de trocá-lo, para o botão do cabeçalho.
class ControleDeTema extends InheritedWidget {
  const ControleDeTema({super.key, required this.escuro, required this.alternar, required super.child});

  /// Se a tela está no tema escuro agora, pela escolha ou pelo sistema.
  final bool escuro;
  final VoidCallback alternar;

  static ControleDeTema? deste(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ControleDeTema>();

  @override
  bool updateShouldNotify(ControleDeTema oldWidget) => escuro != oldWidget.escuro;
}
