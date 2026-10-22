import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import '../tema.dart';

/// Tela pública: o aluno escolhe curso e semestre e vê as aulas da turma.
class TelaDaGrade extends StatefulWidget {
  const TelaDaGrade({super.key, required this.consulta});

  final ConsultaDeGrade consulta;

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
      _resultado = widget.consulta.gradeDaTurma(Turma(curso: curso.curso, turno: curso.turno, semestre: semestre));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _situacao,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const Center(child: CircularProgressIndicator()),
          GradeNaoPublicada() => const Column(children: [_Cabecalho(), _Aviso('Grade ainda não publicada')]),
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
              FutureBuilder(
                future: resultado,
                builder: (context, snapshot) => switch (snapshot.data) {
                  null => const Center(child: CircularProgressIndicator()),
                  GradeNaoPublicada() => const _Aviso('Grade ainda não publicada'),
                  TurmaSemAulas() => const _Aviso('Esta turma não tem aulas nesta grade.'),
                  AulasDaTurma(:final dias) => _ListaPorDia(dias),
                },
              ),
          ],
        ),
      ],
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
        constraints: const BoxConstraints(maxWidth: 720),
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

class _ListaPorDia extends StatelessWidget {
  const _ListaPorDia(this.dias);

  final List<DiaComAulas> dias;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final DiaComAulas(:dia, :aulas) in dias) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              dia.rotulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          for (final aula in aulas) _CartaoDaAula(aula),
          const SizedBox(height: 16),
        ],
      ],
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
        subtitle: Text(aula.professor),
        trailing: Text('Sala ${aula.sala}', style: Theme.of(context).textTheme.titleSmall),
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
