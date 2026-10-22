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

/// As cores de uma disciplina na grade: um fundo suave e uma faixa lateral um pouco mais forte.
typedef CorDaDisciplina = ({Color fundo, Color faixa});

/// Tons suaves e pouco saturados, distintos entre si: azul, verde, areia, lilás, pêssego, verde-água,
/// rosa e cinza-azulado. A partir da nona disciplina, as cores se repetem.
const _fundosClaros = [
  Color(0xFFDCE7F5),
  Color(0xFFDCEFE0),
  Color(0xFFF6EDD3),
  Color(0xFFE7E0F2),
  Color(0xFFF8E3D6),
  Color(0xFFD7EEEC),
  Color(0xFFF3DDE6),
  Color(0xFFE3E7EC),
];
const _fundosEscuros = [
  Color(0xFF2E3B4C),
  Color(0xFF2F4234),
  Color(0xFF47402C),
  Color(0xFF3B344B),
  Color(0xFF4A382D),
  Color(0xFF2A4341),
  Color(0xFF47323C),
  Color(0xFF373C43),
];
const _faixas = [
  Color(0xFF7D9CC8),
  Color(0xFF7DB38C),
  Color(0xFFCDB06A),
  Color(0xFFA391C9),
  Color(0xFFDDA07F),
  Color(0xFF6FB5AF),
  Color(0xFFCF8EA9),
  Color(0xFF939DAA),
];

/// A cor da disciplina na posição [indice] da lista de disciplinas da turma.
CorDaDisciplina corDaDisciplina(int indice, Brightness brilho) {
  final i = indice % _faixas.length;
  final fundos = brilho == Brightness.dark ? _fundosEscuros : _fundosClaros;
  return (fundo: fundos[i], faixa: _faixas[i]);
}

/// As cores do texto sobre o fundo de uma disciplina: a principal e um cinza para o texto secundário.
typedef CoresDoTexto = ({Color principal, Color secundaria});

/// No tema escuro, branco lê melhor sobre os fundos escuros; no claro, o texto escuro do tema.
CoresDoTexto coresDoTextoNoCartao(ThemeData tema) => tema.brightness == Brightness.dark
    ? (principal: Colors.white, secundaria: const Color(0xFFB4BAC2))
    : (principal: tema.colorScheme.onSurface, secundaria: const Color(0xFF5F6670));
