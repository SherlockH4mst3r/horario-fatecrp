import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import '../escritor_de_planilha.dart';
import '../leitor_de_planilha.dart';
import '../telas/avisos.dart';

/// Abre a janela de arquivos e devolve o .xlsx escolhido, ou `null` se o admin desistir.
typedef EscolherPlanilha = Future<Uint8List?> Function();

/// Entrega o .xlsx ao admin com esse nome (no navegador, um download).
typedef SalvarPlanilha = Future<void> Function(String nome, Uint8List bytes);

/// As etapas da importação, na ordem em que o admin passa por elas.
sealed class _Etapa {
  const _Etapa();
}

class _Inicio extends _Etapa {
  const _Inicio({this.problema});

  /// O que impediu a última tentativa, se houve.
  final String? problema;
}

class _NaPrevia extends _Etapa {
  const _NaPrevia(this.previa, {this.problema});

  final Previa previa;

  /// O que impediu a última tentativa de publicar, se houve.
  final String? problema;
}

class _Publicada extends _Etapa {
  const _Publicada(this.semestreLetivo);

  final SemestreLetivo semestreLetivo;
}

/// A importação da planilha: semestre letivo, escolha do .xlsx, prévia e publicação.
class ImportacaoDaPlanilha extends StatefulWidget {
  const ImportacaoDaPlanilha({
    super.key,
    required this.importacao,
    required this.escolherPlanilha,
    required this.salvarPlanilha,
  });

  final ImportacaoDeGrade importacao;
  final EscolherPlanilha escolherPlanilha;
  final SalvarPlanilha salvarPlanilha;

  @override
  State<ImportacaoDaPlanilha> createState() => _ImportacaoDaPlanilhaState();
}

class _ImportacaoDaPlanilhaState extends State<ImportacaoDaPlanilha> {
  final _semestreLetivo = TextEditingController();
  _Etapa _etapa = const _Inicio();
  bool _ocupado = false;

  @override
  void dispose() {
    _semestreLetivo.dispose();
    super.dispose();
  }

  Future<void> _escolherPlanilha() async {
    final semestreLetivo = SemestreLetivo.tentarLer(_semestreLetivo.text);
    if (semestreLetivo == null) {
      setState(() => _etapa = const _Inicio(problema: 'Use ano/período, como 2027/1.'));
      return;
    }
    setState(() => _ocupado = true);
    final _Etapa proxima;
    try {
      final arquivo = await widget.escolherPlanilha();
      proxima = arquivo == null
          ? const _Inicio()
          : _NaPrevia(await widget.importacao.importar(lerPlanilhaXlsx(arquivo), semestreLetivo));
    } on PlanilhaIlegivel catch (erro) {
      _mostrar(_Inicio(problema: 'Não deu para ler o arquivo: ${erro.mensagem}.'), aviso: TipoDeAviso.alerta);
      return;
    } catch (_) {
      _mostrar(
        const _Inicio(problema: 'Não deu para ler a grade publicada, para comparar. Tente de novo.'),
        aviso: TipoDeAviso.erro,
      );
      return;
    }
    _mostrar(proxima);
    if (proxima case _NaPrevia(:final previa) when previa.erros.isNotEmpty && mounted) {
      final quantos = previa.erros.length;
      mostrarAviso(
        context,
        'A planilha tem $quantos ${quantos == 1 ? 'erro' : 'erros'}. Corrija no Excel e importe de novo.',
        TipoDeAviso.alerta,
      );
    }
  }

  Future<void> _publicar(Previa previa) async {
    setState(() => _ocupado = true);
    try {
      await widget.importacao.publicar(previa);
    } catch (_) {
      _mostrar(
        _NaPrevia(previa, problema: 'Não deu para publicar. A grade publicada não mudou; tente de novo.'),
        aviso: TipoDeAviso.erro,
      );
      return;
    }
    _mostrar(_Publicada(previa.semestreLetivo));
    if (mounted) mostrarAviso(context, 'Grade ${previa.semestreLetivo.rotulo} publicada.', TipoDeAviso.sucesso);
  }

  /// Troca de etapa; com [aviso], repete o problema da etapa num snackbar dessa cor.
  void _mostrar(_Etapa etapa, {TipoDeAviso? aviso}) {
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _etapa = etapa;
    });
    final problema = switch (etapa) {
      _Inicio(:final problema) || _NaPrevia(:final problema) => problema,
      _Publicada() => null,
    };
    if (aviso != null && problema != null) mostrarAviso(context, problema, aviso);
  }

  void _recomecar() => setState(() => _etapa = const _Inicio());

  @override
  Widget build(BuildContext context) {
    return switch (_etapa) {
      _Inicio(:final problema) => _escolha(problema),
      _NaPrevia(:final previa, :final problema) => _VistaDaPrevia(
        previa: previa,
        problema: problema,
        ocupado: _ocupado,
        aoPublicar: () => _publicar(previa),
        aoCancelar: _recomecar,
      ),
      _Publicada(:final semestreLetivo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grade ${semestreLetivo.rotulo} publicada.', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('A consulta pública já mostra a nova grade ao recarregar a página.'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              FilledButton(onPressed: _recomecar, child: const Text('Importar outra planilha')),
              OutlinedButton(
                // Abre a consulta do zero, para ela ler a grade recém-publicada.
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
                child: const Text('Ver a grade pública'),
              ),
            ],
          ),
        ],
      ),
    };
  }

  /// Baixa a grade publicada como .xlsx, para o admin editar no Excel e importar de volta.
  Future<void> _baixar() async {
    setState(() => _ocupado = true);
    try {
      final exportada = await widget.importacao.exportar();
      if (exportada == null) {
        _avisar('Ainda não há grade publicada para baixar.', TipoDeAviso.alerta);
        return;
      }
      final SemestreLetivo(:ano, :periodo) = exportada.semestreLetivo;
      await widget.salvarPlanilha(
        'grade_$ano-$periodo.xlsx',
        escreverPlanilhaXlsx(exportada.planilha, aba: 'Grade $ano-$periodo'),
      );
      _avisar(
        'Grade ${exportada.semestreLetivo.rotulo} baixada. Edite no Excel e importe de volta.',
        TipoDeAviso.sucesso,
      );
    } catch (_) {
      _avisar('Não deu para baixar a grade publicada. Tente de novo.', TipoDeAviso.erro);
    }
  }

  void _avisar(String mensagem, TipoDeAviso tipo) {
    if (!mounted) return;
    setState(() => _ocupado = false);
    mostrarAviso(context, mensagem, tipo);
  }

  Widget _escolha(String? problema) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Importar a grade', style: textos.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'A planilha substitui a grade inteira. Uma linha por aula, com as colunas Curso, Turno, Semestre, '
          'Dia, Início, Fim, Disciplina, Professor, Sala e Andar. Para mudar a grade atual, baixe-a, edite no '
          'Excel e importe de volta.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : _baixar,
          icon: const Icon(Icons.download),
          label: const Text('Baixar a grade publicada'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 240,
          child: TextField(
            controller: _semestreLetivo,
            decoration: const InputDecoration(
              labelText: 'Semestre letivo',
              hintText: '2027/1',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _ocupado ? null : _escolherPlanilha,
          icon: const Icon(Icons.upload_file),
          label: const Text('Escolher planilha .xlsx'),
        ),
        if (problema != null) ...[
          const SizedBox(height: 12),
          Text(problema, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}

class _VistaDaPrevia extends StatelessWidget {
  const _VistaDaPrevia({
    required this.previa,
    required this.problema,
    required this.ocupado,
    required this.aoPublicar,
    required this.aoCancelar,
  });

  final Previa previa;
  final String? problema;
  final bool ocupado;
  final VoidCallback aoPublicar;
  final VoidCallback aoCancelar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cores = Theme.of(context).colorScheme;
    final erros = previa.erros;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prévia da grade ${previa.semestreLetivo.rotulo}', style: textos.titleLarge),
        const SizedBox(height: 4),
        Text(
          erros.isEmpty
              ? '${previa.quantidadeDeAulas} aulas, sem erros'
              : '${erros.length} ${erros.length == 1 ? 'erro' : 'erros'}: corrija a planilha e importe de novo',
          style: TextStyle(color: erros.isEmpty ? null : cores.error),
        ),
        if (erros.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final erro in erros)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(_apontamento(erro), style: TextStyle(color: cores.error)),
            ),
        ],
        if (previa.avisos.isNotEmpty) ...[
          const SizedBox(height: 16),
          FaixaDeAviso(
            tipo: TipoDeAviso.alerta,
            titulo: 'Confira antes de publicar (não impede a publicação):',
            detalhes: [for (final aviso in previa.avisos) _apontamento(aviso)],
          ),
        ],
        if (previa.diferencas case final diferencas?) ...[const SizedBox(height: 24), _OQueMuda(diferencas)],
        const SizedBox(height: 24),
        Text('Turmas encontradas (${previa.turmas.length})', style: textos.titleMedium),
        const SizedBox(height: 8),
        _Etiquetas([for (final turma in previa.turmas) turma.rotulo]),
        const SizedBox(height: 16),
        Text('Salas encontradas (${previa.salas.length})', style: textos.titleMedium),
        const SizedBox(height: 8),
        _Etiquetas([for (final (:sala, :andar) in previa.salas) '$sala · ${andar.rotulo}']),
        const SizedBox(height: 8),
        Text('Confira se algum nome aparece escrito de dois jeitos (ex.: "Lab 1" e "lab 1").', style: textos.bodySmall),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(onPressed: previa.podePublicar && !ocupado ? aoPublicar : null, child: const Text('Publicar')),
            OutlinedButton(onPressed: ocupado ? null : aoCancelar, child: const Text('Cancelar')),
          ],
        ),
        if (problema case final problema?) ...[
          const SizedBox(height: 12),
          Text(problema, style: TextStyle(color: cores.error)),
        ],
      ],
    );
  }
}

/// "Linha 2 · Sala: a sala B12 já tem aula nesse horário: ... (conflita com a linha 6)".
String _apontamento(ErroNaPlanilha erro) {
  final ErroNaPlanilha(:linha, :coluna, :mensagem, :outraLinha) = erro;
  return 'Linha $linha · $coluna: $mensagem${outraLinha == null ? '' : ' (conflita com a linha $outraLinha)'}';
}

class _Etiquetas extends StatelessWidget {
  const _Etiquetas(this.textos);

  final List<String> textos;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [for (final texto in textos) Chip(label: Text(texto))]);
  }
}

/// As diferenças da prévia contra a grade publicada: aulas novas, removidas e alteradas, campo a campo.
class _OQueMuda extends StatelessWidget {
  const _OQueMuda(this.diferencas);

  final Diferencas diferencas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final Diferencas(:novas, :removidas, :alteradas) = diferencas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('O que muda na grade publicada', style: textos.titleMedium),
        const SizedBox(height: 8),
        if (diferencas.nenhuma)
          const Text('Nenhuma mudança')
        else ...[
          if (diferencas.semestreLetivo case (:final antes, :final depois)) ...[
            Text('Semestre letivo: ${antes.rotulo} → ${depois.rotulo}'),
            const SizedBox(height: 12),
          ],
          if (novas.isNotEmpty)
            ..._grupo(textos, 'Novas', novas.length, [for (final aula in novas) Text(_descricao(aula))]),
          if (removidas.isNotEmpty)
            ..._grupo(textos, 'Removidas', removidas.length, [for (final aula in removidas) Text(_descricao(aula))]),
          if (alteradas.isNotEmpty)
            ..._grupo(textos, 'Alteradas', alteradas.length, [
              for (final AulaAlterada(:antes, :mudancas) in alteradas) ...[
                Text(_descricao(antes)),
                for (final MudancaDeCampo(:campo, antes: de, depois: para) in mudancas)
                  Padding(padding: const EdgeInsets.only(left: 16), child: Text('$campo: $de → $para')),
              ],
            ]),
        ],
      ],
    );
  }

  List<Widget> _grupo(TextTheme textos, String titulo, int quantidade, List<Widget> linhas) => [
    Text('$titulo ($quantidade)', style: textos.titleSmall),
    const SizedBox(height: 4),
    ...linhas,
    const SizedBox(height: 12),
  ];

  String _descricao(Aula aula) {
    final Aula(:turma, :dia, :inicio, :fim, :disciplina) = aula;
    return '${turma.rotulo} · ${dia.rotulo} $inicio–$fim · $disciplina';
  }
}
