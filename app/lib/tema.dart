import 'package:flutter/material.dart';

/// A partir desta largura de tela, o site se comporta como no computador (grade de horários, fonte maior).
const larguraDeComputador = 840.0;

/// Texto corrido de 16px no computador e de 14px no celular; os demais tamanhos acompanham.
ThemeData comFonteDaTela(ThemeData tema, double larguraDaTela) {
  final computador = larguraDaTela >= larguraDeComputador;
  final corpo = computador ? 16.0 : 14.0;
  final textos = tema.textTheme;
  return tema.copyWith(
    textTheme: textos.copyWith(
      bodyLarge: textos.bodyLarge?.copyWith(fontSize: corpo),
      bodyMedium: textos.bodyMedium?.copyWith(fontSize: corpo),
      bodySmall: textos.bodySmall?.copyWith(fontSize: corpo - 2),
      titleSmall: textos.titleSmall?.copyWith(fontSize: corpo),
    ),
  );
}

/// Vermelho da marca Fatec, aproximado da logo (não há manual público com o código oficial).
const vermelhoFatec = Color(0xFFB20000);

/// Fundo do tema claro: creme claro, que cansa menos que o branco puro.
const fundoClaro = Color(0xFFFBF7EF);

/// Fundo do tema escuro: azul-acinzentado, como jeans, neutro ao lado do vermelho da Fatec.
const fundoEscuro = Color(0xFF1E2631);

ThemeData temaFatec(Brightness brilho) {
  final escuro = brilho == Brightness.dark;
  // Os neutros (fundos, contornos e texto) saem do creme ou do jeans, e não do vermelho, para não cansar a vista;
  // o vermelho fica nos destaques.
  final cores =
      ColorScheme.fromSeed(
        seedColor: vermelhoFatec,
        brightness: brilho,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: escuro ? const Color(0xFFFFB4A8) : vermelhoFatec,
        onPrimary: escuro ? const Color(0xFF690000) : Colors.white,
        surface: escuro ? fundoEscuro : fundoClaro,
        onSurface: escuro ? const Color(0xFFE3E7EC) : const Color(0xFF221D18),
        onSurfaceVariant: escuro ? const Color(0xFFB4BCC6) : const Color(0xFF5E564C),
        surfaceContainerLowest: escuro ? const Color(0xFF19202A) : const Color(0xFFFFFDF8),
        surfaceContainerLow: escuro ? const Color(0xFF222A35) : const Color(0xFFF7F2E8),
        surfaceContainer: escuro ? const Color(0xFF26303B) : const Color(0xFFF3EDE1),
        surfaceContainerHigh: escuro ? const Color(0xFF2C3642) : const Color(0xFFEEE7DA),
        surfaceContainerHighest: escuro ? const Color(0xFF333E4B) : const Color(0xFFE8E0D1),
        outline: escuro ? const Color(0xFF6B7684) : const Color(0xFF8A8073),
        outlineVariant: escuro ? const Color(0xFF3B4552) : const Color(0xFFDCD3C4),
      );
  return ThemeData(
    colorScheme: cores,
    useMaterial3: true,
    scaffoldBackgroundColor: cores.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: escuro ? cores.surfaceContainerLow : cores.surfaceContainerLowest,
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
