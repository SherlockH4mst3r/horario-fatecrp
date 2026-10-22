import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import '../tema.dart';

/// Tela pública: o aluno escolhe curso e semestre e vê as aulas da turma.
class TelaDaGrade extends StatefulWidget {
  const TelaDaGrade({super.key, required this.consulta, required this.relogio});

  final ConsultaDeGrade consulta;
  final DateTime Function() relogio;

  @override
  State<TelaDaGrade> createState() => _TelaDaGradeState();
}

class _TelaDaGradeState extends State<TelaDaGrade> {
  late final Future<SituacaoDaGrade> _situacao = widget.consulta.cursosDisponiveis();
  CursoOferecido? _curso;
  int? _semestre;
  Future<ResultadoDaTurma>? _resultado;

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
      _resultado = widget.consulta.gradeDaTurma(
        Turma(curso: curso.curso, turno: curso.turno, semestre: semestre),
        hoje: widget.relogio(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AoCarregar(
        future: _situacao,
        aoFalhar: (aviso) => Column(children: [const _Cabecalho(), aviso]),
        builder: (situacao) => switch (situacao) {
          GradeNaoPublicada() => const Column(children: [_Cabecalho(), _avisoGradeNaoPublicada]),
          GradePublicada publicada => _conteudo(publicada),
        },
      ),
    );
  }

  Widget _conteudo(GradePublicada publicada) {
    return ListView(
      children: [
        _Cabecalho(semestreLetivo: publicada.semestreLetivo),
        _Coluna(
          children: [
            const SizedBox(height: 24),
            _SeletorDeTurma(
              cursos: publicada.cursos,
              semestres: publicada.semestres,
              curso: _curso,
              semestre: _semestre,
              aoEscolherCurso: _escolherCurso,
              aoEscolherSemestre: _escolherSemestre,
            ),
            const SizedBox(height: 24),
            if (_resultado case final resultado?)
              _AoCarregar(
                future: resultado,
                builder: (resultado) => switch (resultado) {
                  GradeNaoPublicada() => _avisoGradeNaoPublicada,
                  TurmaSemAulas() => const _Aviso('Esta turma não tem aulas nesta grade.'),
                  AulasDaTurma aulas =>
                    MediaQuery.sizeOf(context).width >= _larguraDaGradeDeHorarios
                        ? _GradeDeHorarios(aulas)
                        : _ListaAPartirDeHoje(aulas),
                },
              ),
          ],
        ),
      ],
    );
  }
}

String _local(Aula aula) => 'Sala ${aula.sala} · ${aula.andar.rotulo}';

const _avisoGradeNaoPublicada = _Aviso('Grade ainda não publicada');

/// Largura máxima do conteúdo em telas grandes.
const _larguraMaxima = 1200.0;

/// A partir desta largura de tela cabem seis dias lado a lado; abaixo dela, a grade vira lista.
const _larguraDaGradeDeHorarios = 840.0;

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

/// Faixa vermelha do topo, com o nome da faculdade e o semestre letivo.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({this.semestreLetivo});

  final SemestreLetivo? semestreLetivo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Material(
      color: vermelhoFatec,
      child: SafeArea(
        bottom: false,
        child: _Coluna(
          children: [
            const SizedBox(height: 20),
            Text('FATEC RIBEIRÃO PRETO', style: textos.labelLarge?.copyWith(color: Colors.white70, letterSpacing: 1.5)),
            if (semestreLetivo case final semestre?)
              Text(
                'Grade ${semestre.rotulo}',
                style: textos.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Limita a largura do conteúdo em telas grandes, com margem lateral no celular.
class _Coluna extends StatelessWidget {
  const _Coluna({required this.children});

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

class _SeletorDeTurma extends StatelessWidget {
  const _SeletorDeTurma({
    required this.cursos,
    required this.semestres,
    required this.curso,
    required this.semestre,
    required this.aoEscolherCurso,
    required this.aoEscolherSemestre,
  });

  final List<CursoOferecido> cursos;
  final List<int> semestres;
  final CursoOferecido? curso;
  final int? semestre;
  final ValueChanged<CursoOferecido?> aoEscolherCurso;
  final ValueChanged<int?> aoEscolherSemestre;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
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
    // Na grade do computador o texto vai 2px acima do padrão do tema, para ler de longe.
    Text linha(String texto, TextStyle? estilo, {bool secundaria = false}) => Text(
      texto,
      style: estilo?.copyWith(
        color: secundaria ? corDoTexto.secundaria : corDoTexto.principal,
        fontSize: (estilo.fontSize ?? 14) + 2,
      ),
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
            linha(_local(aula), textos.bodySmall),
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
            Text(_local(aula), style: TextStyle(color: corDoTexto.principal)),
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
