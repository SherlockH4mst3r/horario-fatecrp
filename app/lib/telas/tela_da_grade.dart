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
                    MediaQuery.sizeOf(context).width >= _larguraDaTabela
                        ? _TabelaDaSemana(aulas)
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
const _larguraDaTabela = 840.0;

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

/// Semana em tabela, para telas largas: uma coluna por dia e uma linha por horário de início.
class _TabelaDaSemana extends StatelessWidget {
  const _TabelaDaSemana(this.aulas);

  final AulasDaTurma aulas;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Table(
      border: TableBorder.all(color: cores.outlineVariant),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: [
        TableRow(
          decoration: const BoxDecoration(color: vermelhoFatec),
          children: [
            const SizedBox.shrink(),
            for (final DiaComAulas(:dia) in aulas.semana)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(dia.rotulo, style: textos.titleSmall?.copyWith(color: Colors.white)),
              ),
          ],
        ),
        for (final inicio in aulas.inicios)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '$inicio',
                  style: TextStyle(color: cores.primary, fontWeight: FontWeight.bold),
                ),
              ),
              for (final DiaComAulas(aulas: aulasDoDia) in aulas.semana)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final aula in aulasDoDia)
                      if (aula.inicio == inicio) _AulaNaTabela(aula),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

class _AulaNaTabela extends StatelessWidget {
  const _AulaNaTabela(this.aula);

  final Aula aula;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(aula.disciplina, style: textos.titleSmall),
          Text(aula.professor, style: textos.bodySmall),
          Text(_local(aula), style: textos.bodySmall),
          Text('${aula.inicio} – ${aula.fim}', style: textos.bodySmall),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grade.hoje case final hoje?) ...[
          _TituloDoDia('${hoje.dia.rotulo} · hoje'),
          if (hoje.aulas.isEmpty) const _Aviso('Sem aulas hoje') else ...hoje.aulas.map(_CartaoDaAula.new),
          const SizedBox(height: 16),
        ],
        for (final DiaComAulas(:dia, :aulas) in grade.proximosDias) ...[
          _TituloDoDia(dia.rotulo),
          ...aulas.map(_CartaoDaAula.new),
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
  const _CartaoDaAula(this.aula);

  final Aula aula;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(
          '${aula.inicio}\n${aula.fim}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        title: Text(aula.disciplina),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(aula.professor), Text(_local(aula))],
        ),
        isThreeLine: true,
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
