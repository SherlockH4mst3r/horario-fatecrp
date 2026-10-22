import 'package:flutter/material.dart';

/// Vermelho da marca Fatec, aproximado da logo (não há manual público com o código oficial).
const vermelhoFatec = Color(0xFFB20000);

ThemeData temaFatec(Brightness brilho) {
  final escuro = brilho == Brightness.dark;
  final cores =
      ColorScheme.fromSeed(
        seedColor: vermelhoFatec,
        brightness: brilho,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: escuro ? const Color(0xFFFFB4A8) : vermelhoFatec,
        onPrimary: escuro ? const Color(0xFF690000) : Colors.white,
        surface: escuro ? null : Colors.white,
      );
  return ThemeData(
    colorScheme: cores,
    useMaterial3: true,
    scaffoldBackgroundColor: cores.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: cores.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cores.outlineVariant),
      ),
    ),
  );
}
