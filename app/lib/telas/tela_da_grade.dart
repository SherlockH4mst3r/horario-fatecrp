import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import '../tema.dart';
import 'moldura.dart';

/// Tela pública: o aluno escolhe curso e semestre e vê as aulas da turma.
class TelaDaGrade extends StatefulWidget {
  const TelaDaGrade({super.key, required this.consulta, required this.relogio});

  final ConsultaDeGrade consulta;
  final DateTime Function() relogio;

  @override
  State<TelaDaGrade> createState() => _TelaDaGradeState();
}

class _TelaDaGradeState extends State<TelaDaGrade> {
  // A falha ao carregar já aparece na tela pelo _AoCarregar; aqui só não há turma para abrir.
  late Future<SituacaoDaGrade> _situacao = widget.consulta.cursosDisponiveis()
    ..then(_abrirTurmaLembrada, onError: (Object _) {});
  CursoOferecido? _curso;
  int? _semestre;
  Future<ResultadoDaTurma>? _resultado;

  void _abrirTurmaLembrada(SituacaoDaGrade situacao) {
    if (situacao case GradePublicada(turmaLembrada: (:final curso, :final semestre)) when mounted) {
      setState(() {
        _curso = curso;
        _semestre = semestre;
        _resultado = widget.consulta.gradeDaTurma(curso.turma(semestre), hoje: widget.relogio());
      });
    }
  }

  /// Relê a grade publicada (o painel pode ter publicado em outra aba) e mantém a turma escolhida, se ela
  /// ainda existir.
  Future<void> _recarregar() async {
    final situacao = widget.consulta.cursosDisponiveis();
    setState(() {
      _situacao = situacao;
    });
    final SituacaoDaGrade recarregada;
    try {
      recarregada = await situacao;
    } catch (_) {
      return; // O aviso de falha já aparece na tela.
    }
    if (!mounted) return;
    final escolhido = _curso;
    final curso = switch (recarregada) {
      GradePublicada(:final cursos) when escolhido != null =>
        cursos.where((c) => c.curso == escolhido.curso && c.turno == escolhido.turno).firstOrNull,
      _ => null,
    };
    final semestre = _semestre;
    setState(() {
      _curso = curso;
      _semestre = curso == null ? null : semestre;
      _resultado = curso == null || semestre == null
          ? null
          : widget.consulta.gradeDaTurma(curso.turma(semestre), hoje: widget.relogio());
    });
    await _resultado;
  }

  void _escolherCurso(CursoOferecido? curso) {
    setState(() {
      _curso = curso;
      _semestre = null;
      _resultado = null;
    });
  }

  void _escolherSemestre(int? semestre) {
    final curso = _curso;
    if (curso == null || semestre == null) return;
    setState(() {
      _semestre = semestre;
      _resultado = widget.consulta.escolher(curso.turma(semestre), hoje: widget.relogio());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AoCarregar(
        future: _situacao,
        aoFalhar: (aviso) => _rolavel([const CabecalhoFatec(), aviso]),
        builder: (situacao) => switch (situacao) {
          GradeNaoPublicada() => _rolavel(const [CabecalhoFatec(), _avisoGradeNaoPublicada]),
          GradePublicada publicada => _conteudo(publicada),
        },
      ),
    );
  }

  /// Puxar a tela para baixo recarrega a grade, inclusive quando ela ainda não foi publicada ou falhou.
  Widget _rolavel(List<Widget> filhos) => RefreshIndicator(
    onRefresh: _recarregar,
    child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: filhos),
  );

  Widget _conteudo(GradePublicada publicada) {
    return _rolavel([
      CabecalhoFatec(titulo: 'Grade ${publicada.semestreLetivo.rotulo}'),
      ColunaDeConteudo(
        children: [
          const SizedBox(height: 24),
          _SeletorDeTurma(
            cursos: publicada.cursos,
            semestres: publicada.semestres,
            curso: _curso,
            semestre: _semestre,
            aoEscolherCurso: _escolherCurso,
            aoEscolherSemestre: _escolherSemestre,
            aoRecarregar: _recarregar,
          ),
          const SizedBox(height: 24),
          if (_resultado case final resultado?)
            _AoCarregar(
              future: resultado,
              builder: (resultado) => switch (resultado) {
                GradeNaoPublicada() => _avisoGradeNaoPublicada,
                TurmaSemAulas() => const _Aviso('Esta turma não tem aulas nesta grade.'),
                AulasDaTurma aulas =>
                  MediaQuery.sizeOf(context).width >= larguraDeComputador
                      ? _GradeDeHorarios(aulas)
                      : _ListaAPartirDeHoje(aulas),
              },
            ),
        ],
      ),
    ]);
  }
}

/// "Sala S4/L3 · 1º andar/3º andar"; sem andar quando a sala está a definir.
String _salaComAndar(Aula aula) =>
    aula.andares.isEmpty ? 'Sala ${aula.sala}' : 'Sala ${aula.sala} · ${aula.andaresPorExtenso}';

const _avisoGradeNaoPublicada = _Aviso('Grade ainda não publicada');

/// Espera a consulta: mostra o progresso enquanto carrega e um aviso se ela falhar.
class _AoCarregar<T> extends StatelessWidget {
  const _AoCarregar({required this.future, required this.builder, this.aoFalhar});

  final Future<T> future;
  final Widget Function(T dados) builder;

  /// Encaixa o aviso de falha na tela; sem ele, o aviso aparece sozinho.
  final Widget Function(Widget aviso)? aoFalhar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          const aviso = _Aviso('Não foi possível carregar a grade. Tente recarregar a página.');
          return aoFalhar?.call(aviso) ?? aviso;
        }
        if (snapshot.data case final dados?) return builder(dados);
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _SeletorDeTurma extends StatelessWidget {
  const _SeletorDeTurma({
    required this.cursos,
    required this.semestres,
    required this.curso,
    required this.semestre,
    required this.aoEscolherCurso,
    required this.aoEscolherSemestre,
    required this.aoRecarregar,
  });

  final List<CursoOferecido> cursos;
  final List<int> semestres;
  final CursoOferecido? curso;
  final int? semestre;
  final ValueChanged<CursoOferecido?> aoEscolherCurso;
  final ValueChanged<int?> aoEscolherSemestre;
  final VoidCallback aoRecarregar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16,
      children: [
        DropdownMenu<CursoOferecido>(
          label: const Text('Curso'),
          width: 320,
          initialSelection: curso,
          onSelected: aoEscolherCurso,
          dropdownMenuEntries: [for (final c in cursos) DropdownMenuEntry(value: c, label: c.rotulo)],
        ),
        DropdownMenu<int>(
          // A chave troca com o curso para limpar o semestre escolhido antes.
          key: ValueKey(curso),
          label: const Text('Semestre'),
          width: 160,
          enabled: curso != null,
          initialSelection: semestre,
          onSelected: aoEscolherSemestre,
          dropdownMenuEntries: [for (final s in semestres) DropdownMenuEntry(value: s, label: '$sº')],
        ),
        // No celular, puxar a tela para baixo faz o mesmo.
        if (MediaQuery.sizeOf(context).width >= larguraDeComputador)
          IconButton.outlined(tooltip: 'Recarregar', icon: const Icon(Icons.refresh), onPressed: aoRecarregar),
      ],
    );
  }
}

/// Semana em grade de horários, para telas largas: uma coluna por dia, a régua de horas à esquerda
/// e cada aula como um bloco com a altura da sua duração.
class _GradeDeHorarios extends StatelessWidget {
  const _GradeDeHorarios(this.grade);

  final AulasDaTurma grade;

  static const _pixelsPorMinuto = 1.4;
  static const _larguraDaRegua = 56.0;

  double _distanciaDoTopo(Horario horario) => horario.minutosDesde(grade.horas.first) * _pixelsPorMinuto;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final linhaDaHora = Divider(height: 1, color: cores.outlineVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: vermelhoFatec,
          child: Row(
            children: [
              const SizedBox(width: _larguraDaRegua),
              for (final DiaComAulas(:dia) in grade.semana)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(dia.rotulo, style: textos.titleSmall?.copyWith(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: _distanciaDoTopo(grade.horas.last),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _larguraDaRegua,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final hora in grade.horas)
                      Positioned(
                        top: _distanciaDoTopo(hora) + 4,
                        left: 8,
                        child: Text('$hora', style: textos.labelSmall?.copyWith(color: cores.primary)),
                      ),
                  ],
                ),
              ),
              for (final DiaComAulas(:aulas) in grade.semana)
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: cores.outlineVariant)),
                    ),
                    child: Stack(
                      children: [
                        for (final hora in grade.horas)
                          Positioned(top: _distanciaDoTopo(hora), left: 0, right: 0, child: linhaDaHora),
                        for (final aula in aulas)
                          Positioned(
                            top: _distanciaDoTopo(aula.inicio),
                            height: aula.fim.minutosDesde(aula.inicio) * _pixelsPorMinuto,
                            left: 4,
                            right: 4,
                            child: _BlocoDaAula(aula, cor: _corDa(context, grade, aula)),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BlocoDaAula extends StatelessWidget {
  const _BlocoDaAula(this.aula, {required this.cor});

  final Aula aula;
  final CorDaDisciplina cor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final corDoTexto = coresDoTextoNoCartao(Theme.of(context));
    Text linha(String texto, TextStyle? estilo, {bool secundaria = false}) => Text(
      texto,
      style: estilo?.copyWith(color: secundaria ? corDoTexto.secundaria : corDoTexto.principal),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return _CartaoColorido(
      cor: cor,
      margem: const EdgeInsets.symmetric(vertical: 2),
      // Aula curta não tem altura para tudo: o texto que sobra é cortado, sem erro de layout.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            linha(aula.disciplina, textos.titleSmall),
            linha('${aula.inicio} – ${aula.fim}', textos.bodySmall),
            linha(aula.professor, textos.bodySmall, secundaria: true),
            linha(_salaComAndar(aula), textos.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Lista para telas estreitas: hoje primeiro (exceto no domingo), depois os próximos dias com aula.
class _ListaAPartirDeHoje extends StatelessWidget {
  const _ListaAPartirDeHoje(this.grade);

  final AulasDaTurma grade;

  @override
  Widget build(BuildContext context) {
    Widget cartao(Aula aula) => _CartaoDaAula(aula, cor: _corDa(context, grade, aula));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grade.hoje case final hoje?) ...[
          _TituloDoDia('${hoje.dia.rotulo} · hoje'),
          if (hoje.aulas.isEmpty) const _Aviso('Sem aulas hoje') else ...hoje.aulas.map(cartao),
          const SizedBox(height: 16),
        ],
        for (final DiaComAulas(:dia, :aulas) in grade.proximosDias) ...[
          _TituloDoDia(dia.rotulo),
          ...aulas.map(cartao),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _TituloDoDia extends StatelessWidget {
  const _TituloDoDia(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        titulo,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CartaoDaAula extends StatelessWidget {
  const _CartaoDaAula(this.aula, {required this.cor});

  final Aula aula;
  final CorDaDisciplina cor;

  @override
  Widget build(BuildContext context) {
    final corDoTexto = coresDoTextoNoCartao(Theme.of(context));
    return _CartaoColorido(
      cor: cor,
      margem: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(
          '${aula.inicio}\n${aula.fim}',
          textAlign: TextAlign.center,
          style: TextStyle(color: corDoTexto.principal, fontWeight: FontWeight.bold),
        ),
        title: Text(aula.disciplina, style: TextStyle(color: corDoTexto.principal)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(aula.professor, style: TextStyle(color: corDoTexto.secundaria)),
            Text(_salaComAndar(aula), style: TextStyle(color: corDoTexto.principal)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

CorDaDisciplina _corDa(BuildContext context, AulasDaTurma grade, Aula aula) =>
    corDaDisciplina(grade.disciplinas.indexOf(aula.disciplina), Theme.of(context).brightness);

/// Cartão com o fundo suave da disciplina e uma faixa da mesma cor, mais forte, à esquerda.
class _CartaoColorido extends StatelessWidget {
  const _CartaoColorido({required this.cor, required this.margem, required this.child});

  final CorDaDisciplina cor;
  final EdgeInsets margem;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margem,
      color: cor.fundo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: cor.faixa, width: 4)),
        ),
        child: child,
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.mensagem);

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(mensagem, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
