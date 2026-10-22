import 'grade.dart';
import 'repositorio_grade.dart';

/// Situação da grade vista pelo aluno.
sealed class SituacaoDaGrade {
  const SituacaoDaGrade();
}

/// Nenhuma grade foi importada ainda.
class GradeNaoPublicada implements SituacaoDaGrade, ResultadoDaTurma {
  const GradeNaoPublicada();
}

class GradePublicada extends SituacaoDaGrade {
  const GradePublicada({required this.semestreLetivo, required this.cursos});

  final SemestreLetivo semestreLetivo;
  final List<CursoOferecido> cursos;

  /// Todo curso vai do 1º ao 6º semestre, mesmo que a grade não traga aulas de algum.
  List<int> get semestres => const [1, 2, 3, 4, 5, 6];
}

/// Opção do seletor: um curso num turno.
class CursoOferecido {
  const CursoOferecido({required this.curso, required this.turno});

  final String curso;
  final Turno turno;

  String get rotulo => '$curso – ${turno.rotulo}';
}

/// O que o aluno vê ao abrir a grade de uma turma.
sealed class ResultadoDaTurma {
  const ResultadoDaTurma();
}

class AulasDaTurma extends ResultadoDaTurma {
  const AulasDaTurma({
    required this.semestreLetivo,
    required this.semana,
    required this.inicios,
    required this.hoje,
    required this.proximosDias,
  });

  final SemestreLetivo semestreLetivo;

  /// A semana da turma: de segunda a sexta, com ou sem aula, e o sábado só quando há aula nele.
  final List<DiaComAulas> semana;

  /// Os horários distintos em que a turma começa uma aula, em ordem.
  final List<Horario> inicios;

  /// O dia de hoje, mesmo sem aula; `null` no domingo.
  final DiaComAulas? hoje;

  /// Os dias com aula depois de hoje, na ordem da semana e voltando à segunda depois do sábado.
  /// No domingo, começam na segunda.
  final List<DiaComAulas> proximosDias;
}

class TurmaSemAulas extends ResultadoDaTurma {
  const TurmaSemAulas({required this.semestreLetivo});

  final SemestreLetivo semestreLetivo;
}

class DiaComAulas {
  const DiaComAulas({required this.dia, required this.aulas});

  final DiaDaSemana dia;

  /// Em ordem de início.
  final List<Aula> aulas;
}

/// Caso de uso do aluno: escolher a turma e ver as aulas dela.
class ConsultaDeGrade {
  ConsultaDeGrade(this._repositorio);

  final RepositorioGrade _repositorio;

  Future<SituacaoDaGrade> cursosDisponiveis() async {
    final grade = await _repositorio.gradeAtual();
    if (grade == null) return const GradeNaoPublicada();
    return GradePublicada(semestreLetivo: grade.semestreLetivo, cursos: _cursosOferecidos(grade));
  }

  Future<ResultadoDaTurma> gradeDaTurma(Turma turma, {required DateTime hoje}) async {
    final grade = await _repositorio.gradeAtual();
    if (grade == null) return const GradeNaoPublicada();
    final aulas = grade.aulas.where((aula) => aula.turma == turma).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    if (aulas.isEmpty) return TurmaSemAulas(semestreLetivo: grade.semestreLetivo);
    final porDia = {
      for (final dia in DiaDaSemana.values)
        dia: DiaComAulas(
          dia: dia,
          aulas: [
            for (final aula in aulas)
              if (aula.dia == dia) aula,
          ],
        ),
    };
    final diaDeHoje = DiaDaSemana.letivoDe(hoje);
    final diasSeguintes = diaDeHoje?.seguintes ?? DiaDaSemana.values;
    return AulasDaTurma(
      semestreLetivo: grade.semestreLetivo,
      semana: [
        for (final dia in porDia.values)
          if (dia.dia != DiaDaSemana.sabado || dia.aulas.isNotEmpty) dia,
      ],
      inicios: {for (final aula in aulas) aula.inicio}.toList(),
      hoje: porDia[diaDeHoje],
      proximosDias: [
        for (final dia in diasSeguintes)
          if (porDia[dia]! case final dia when dia.aulas.isNotEmpty) dia,
      ],
    );
  }

  List<CursoOferecido> _cursosOferecidos(Grade grade) {
    final cursosETurnos = {for (final Aula(:turma) in grade.aulas) (turma.curso, turma.turno)};
    final cursos = [for (final (curso, turno) in cursosETurnos) CursoOferecido(curso: curso, turno: turno)];
    return cursos..sort((a, b) => a.rotulo.compareTo(b.rotulo));
  }
}
