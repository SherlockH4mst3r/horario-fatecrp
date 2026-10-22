import 'package:flutter/material.dart';

/// De onde vem o aviso, e por isso a cor dele.
enum TipoDeAviso {
  /// Deu certo: verde.
  sucesso(fundo: Color(0xFF2E7D32), texto: Colors.white, icone: Icons.check_circle_outline),

  /// O que o usuário fez pede atenção, como um conflito de horário ou um campo inválido: amarelo.
  alerta(fundo: Color(0xFFF9A825), texto: Color(0xFF1F1B16), icone: Icons.warning_amber_rounded),

  /// O sistema falhou, como o banco fora do ar: vermelho.
  erro(fundo: Color(0xFFC62828), texto: Colors.white, icone: Icons.error_outline);

  const TipoDeAviso({required this.fundo, required this.texto, required this.icone});

  final Color fundo;
  final Color texto;
  final IconData icone;
}

/// Mostra um snackbar na cor do [tipo].
void mostrarAviso(BuildContext context, String mensagem, TipoDeAviso tipo) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: tipo.fundo,
        showCloseIcon: true,
        closeIconColor: tipo.texto,
        duration: Duration(seconds: tipo == TipoDeAviso.sucesso ? 4 : 8),
        content: Row(
          children: [
            Icon(tipo.icone, color: tipo.texto),
            const SizedBox(width: 12),
            Expanded(
              child: Text(mensagem, style: TextStyle(color: tipo.texto)),
            ),
          ],
        ),
      ),
    );
}

/// O mesmo aviso como faixa, para dentro de um diálogo, onde o snackbar ficaria escondido atrás dele.
class FaixaDeAviso extends StatelessWidget {
  const FaixaDeAviso({super.key, required this.tipo, required this.titulo, this.detalhes = const []});

  final TipoDeAviso tipo;
  final String titulo;

  /// O que precisa ser corrigido ou conferido, um por linha, abaixo do título: 2px menor e em negrito.
  final List<String> detalhes;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: tipo.fundo, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tipo.icone, color: tipo.texto),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(color: tipo.texto)),
                  for (final detalhe in detalhes)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(detalhe, style: estiloDoDetalhe(context, tipo)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O texto do detalhe de uma faixa: 2px menor que o texto corrido e em negrito.
TextStyle estiloDoDetalhe(BuildContext context, TipoDeAviso tipo) {
  final corrido = DefaultTextStyle.of(context).style.fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;
  return TextStyle(color: tipo.texto, fontSize: corrido - 2, fontWeight: FontWeight.bold);
}
