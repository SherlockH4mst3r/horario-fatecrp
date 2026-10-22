import 'package:flutter/material.dart';

import '../preferencia_de_tema.dart';
import '../tema.dart';

/// Largura máxima do conteúdo em telas grandes.
const _larguraMaxima = 1200.0;

/// Faixa vermelha do topo, com o nome da faculdade, o título da tela e, à direita, uma ação opcional.
class CabecalhoFatec extends StatelessWidget {
  const CabecalhoFatec({super.key, this.titulo, this.acao});

  final String? titulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Material(
      color: vermelhoFatec,
      child: SafeArea(
        bottom: false,
        child: ColunaDeConteudo(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FATEC RIBEIRÃO PRETO',
                        style: textos.labelLarge?.copyWith(color: Colors.white70, letterSpacing: 1.5),
                      ),
                      if (titulo case final titulo?)
                        Text(
                          titulo,
                          style: textos.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                const BotaoDeTema(),
                if (acao case final acao?) ...[const SizedBox(width: 8), acao],
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Limita a largura do conteúdo em telas grandes, com margem lateral no celular.
class ColunaDeConteudo extends StatelessWidget {
  const ColunaDeConteudo({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _larguraMaxima),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// Troca entre o tema claro e o escuro. Some fora do app (nos testes de uma tela só, por exemplo).
class BotaoDeTema extends StatelessWidget {
  const BotaoDeTema({super.key});

  @override
  Widget build(BuildContext context) {
    final controle = ControleDeTema.deste(context);
    if (controle == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: controle.escuro ? 'Usar o tema claro' : 'Usar o tema escuro',
      color: Colors.white,
      icon: Icon(controle.escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: controle.alternar,
    );
  }
}
