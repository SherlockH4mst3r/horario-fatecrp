import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import '../telas/avisos.dart';

/// Correção de aulas avulsas no painel: lista as aulas de uma turma e cria, edita ou exclui uma delas sem
/// reimportar a planilha.
class CorrecaoDeAulas extends StatefulWidget {
  const CorrecaoDeAulas({super.key, required this.edicao});

  final EdicaoDeAulas edicao;

  @override
  State<CorrecaoDeAulas> createState() => _CorrecaoDeAulasState();
}

class _CorrecaoDeAulasState extends State<CorrecaoDeAulas> {
  List<Turma>? _turmas;
  Turma? _turma;
  List<Aula> _aulas = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Relê a grade publicada, mantendo a turma escolhida quando ela ainda existe.
  Future<void> _carregar({Turma? turma}) async {
    final turmas = await widget.edicao.turmas();
    final escolhida = turmas.contains(turma ?? _turma) ? (turma ?? _turma) : turmas.firstOrNull;
    final aulas = escolhida == null ? const <Aula>[] : await widget.edicao.aulasDaTurma(escolhida);
    if (!mounted) return;
    setState(() {
      _turmas = turmas;
      _turma = escolhida;
      _aulas = aulas;
    });
  }

  Future<void> _abrirFormulario({Aula? original}) async {
    final turma = _turma;
    final inicial = switch (original) {
      final aula? => AulaDigitada.de(aula),
      null => _aulaNova(turma),
    };
    final salva = await showDialog<AulaSalva>(
      context: context,
      builder: (_) => _FormularioDeAula(edicao: widget.edicao, inicial: inicial, original: original),
    );
    if (salva == null) return;
    await _carregar();
    if (!mounted) return;
    if (salva.avisos.isEmpty) {
      mostrarAviso(context, 'Aula salva. $_naConsulta', TipoDeAviso.sucesso);
    } else {
      mostrarAviso(context, 'Aula salva, mas confira: ${salva.avisos.join('; ')}.', TipoDeAviso.alerta);
    }
  }

  static const _naConsulta = 'A consulta pública mostra a mudança ao recarregar.';

  /// Uma aula em branco na turma escolhida, no primeiro horário do turno.
  AulaDigitada _aulaNova(Turma? turma) {
    final (inicio, fim) = turma?.turno == Turno.noite ? ('19:00', '20:40') : ('07:40', '09:20');
    return AulaDigitada(
      curso: turma?.curso ?? '',
      turno: (turma?.turno ?? Turno.noite).rotulo,
      semestre: '${turma?.semestre ?? 1}',
      dia: DiaDaSemana.segunda.rotulo,
      inicio: inicio,
      fim: fim,
      disciplina: '',
      professor: '',
      sala: '',
      andar: '',
    );
  }

  Future<void> _excluir(Aula aula) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Excluir a aula?'),
        content: Text('${aula.disciplina} · ${aula.dia.rotulo} ${aula.inicio}–${aula.fim} · ${aula.turma.rotulo}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Excluir')),
        ],
      ),
    );
    if (!(confirmou ?? false)) return;
    try {
      await widget.edicao.excluir(aula);
    } catch (_) {
      if (mounted) {
        mostrarAviso(context, 'Não deu para excluir: falha ao gravar a grade. Tente de novo.', TipoDeAviso.erro);
      }
      return;
    }
    await _carregar();
    if (mounted) mostrarAviso(context, 'Aula excluída. $_naConsulta', TipoDeAviso.sucesso);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final turmas = _turmas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Corrigir aulas', style: textos.titleLarge),
        const SizedBox(height: 8),
        const Text('Crie, edite ou exclua uma aula sem reimportar a planilha. Valem as mesmas regras da importação.'),
        const SizedBox(height: 16),
        if (turmas == null)
          const Center(child: CircularProgressIndicator())
        else if (turmas.isEmpty)
          const Text('Ainda não há grade publicada. Importe uma planilha primeiro.')
        else ...[
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownMenu<Turma>(
                // A chave troca com a lista, para o menu mostrar a turma escolhida depois de recarregar.
                key: ValueKey(turmas),
                label: const Text('Turma'),
                width: 320,
                initialSelection: _turma,
                onSelected: (turma) => _carregar(turma: turma),
                dropdownMenuEntries: [for (final turma in turmas) DropdownMenuEntry(value: turma, label: turma.rotulo)],
              ),
              FilledButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Nova aula'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final aula in _aulas)
            Card(
              child: ListTile(
                title: Text(aula.disciplina),
                subtitle: Text(
                  '${aula.dia.rotulo} ${aula.inicio}–${aula.fim} · ${aula.professor} · Sala ${aula.sala}'
                  '${aula.andares.isEmpty ? '' : ' · ${aula.andaresPorExtenso}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _abrirFormulario(original: aula),
                    ),
                    IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _excluir(aula),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// O formulário de uma aula: os mesmos campos da planilha, com o erro de cada um embaixo dele.
class _FormularioDeAula extends StatefulWidget {
  const _FormularioDeAula({required this.edicao, required this.inicial, required this.original});

  final EdicaoDeAulas edicao;
  final AulaDigitada inicial;

  /// A aula que está sendo editada; `null` ao criar.
  final Aula? original;

  @override
  State<_FormularioDeAula> createState() => _FormularioDeAulaState();
}

class _FormularioDeAulaState extends State<_FormularioDeAula> {
  late final _curso = TextEditingController(text: widget.inicial.curso);
  late String _turno = widget.inicial.turno;
  late String _semestre = widget.inicial.semestre;
  late String _dia = widget.inicial.dia;
  late final _inicio = TextEditingController(text: widget.inicial.inicio);
  late final _fim = TextEditingController(text: widget.inicial.fim);
  late final _disciplina = TextEditingController(text: widget.inicial.disciplina);
  late final _professor = TextEditingController(text: widget.inicial.professor);
  late final _sala = TextEditingController(text: widget.inicial.sala);
  late final _andar = TextEditingController(text: widget.inicial.andar);
  Map<String, String> _erros = const {};

  /// Falha do sistema ao gravar, sem culpa do que foi digitado.
  String? _falha;
  bool _salvando = false;

  @override
  void dispose() {
    for (final campo in [_curso, _inicio, _fim, _disciplina, _professor, _sala, _andar]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _falha = null;
    });
    final ResultadoDaEdicao resultado;
    try {
      resultado = await widget.edicao.salvar(
        AulaDigitada(
          curso: _curso.text,
          turno: _turno,
          semestre: _semestre,
          dia: _dia,
          inicio: _inicio.text,
          fim: _fim.text,
          disciplina: _disciplina.text,
          professor: _professor.text,
          sala: _sala.text,
          andar: _andar.text,
        ),
        original: widget.original,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _falha = 'Não deu para salvar: falha ao gravar a grade. Tente de novo.';
        });
      }
      return;
    }
    if (!mounted) return;
    switch (resultado) {
      case AulaSalva():
        Navigator.of(context).pop(resultado);
      case AulaRecusada(:final erros):
        setState(() {
          _salvando = false;
          _erros = erros;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.original == null ? 'Nova aula' : 'Editar aula'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_falha case final falha?) ...[
                FaixaDeAviso(tipo: TipoDeAviso.erro, titulo: falha),
                const SizedBox(height: 12),
              ] else if (_erros.isNotEmpty) ...[
                FaixaDeAviso(
                  tipo: TipoDeAviso.alerta,
                  titulo: 'Não deu para salvar. Corrija o que está marcado:',
                  detalhes: [..._erros.values],
                ),
                const SizedBox(height: 16),
              ],
              _texto(_curso, 'Curso'),
              _escolha('Turno', _turno, [for (final turno in Turno.values) turno.rotulo], (v) => _turno = v),
              _escolha('Semestre', _semestre, [for (final s in semestresDoCurso) '$s'], (v) => _semestre = v),
              _escolha('Dia', _dia, [for (final dia in DiaDaSemana.values) dia.rotulo], (v) => _dia = v),
              Row(
                children: [
                  Expanded(child: _texto(_inicio, 'Início', dica: '19:00')),
                  const SizedBox(width: 12),
                  Expanded(child: _texto(_fim, 'Fim', dica: '20:40')),
                ],
              ),
              _texto(_disciplina, 'Disciplina'),
              _texto(_professor, 'Professor'),
              _texto(_sala, 'Sala', dica: 'S14, ou L1/S2 se a aula alterna entre duas salas'),
              _texto(_andar, 'Andar', dica: '1º andar, ou 1º andar/3º andar numa sala dupla'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _salvando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _salvando ? null : _salvar, child: const Text('Salvar')),
      ],
    );
  }

  Widget _texto(TextEditingController controle, String coluna, {String? dica}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controle,
      decoration: InputDecoration(
        labelText: coluna,
        helperText: dica,
        errorText: _erros[coluna],
        errorMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _escolha(String coluna, String valor, List<String> opcoes, ValueChanged<String> aoEscolher) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: opcoes.contains(valor) ? valor : null,
      decoration: InputDecoration(labelText: coluna, errorText: _erros[coluna], border: const OutlineInputBorder()),
      items: [for (final opcao in opcoes) DropdownMenuItem(value: opcao, child: Text(opcao))],
      onChanged: (opcao) {
        if (opcao != null) setState(() => aoEscolher(opcao));
      },
    ),
  );
}
