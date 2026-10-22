import 'grade.dart';
import 'memoria_da_turma.dart';
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
  const GradePublicada({required this.semestreLetivo, required this.cursos, this.turmaLembrada});

  final SemestreLetivo semestreLetivo;
  final List<CursoOferecido> cursos;

  /// A última turma que o aluno escolheu, se ela ainda tem aulas nesta grade.
  final EscolhaDeTurma? turmaLembrada;

  /// Todo curso vai do 1º ao 6º semestre, mesmo que a grade não traga aulas de algum.
  List<int> get semestres => const [1, 2, 3, 4, 5, 6];
}

/// Uma turma como o seletor a mostra: o curso oferecido e o semestre.
typedef EscolhaDeTurma = ({CursoOferecido curso, int semestre});

/// Opção do seletor: um curso num turno.
class CursoOferecido {
  const CursoOferecido({required this.curso, required this.turno});

  final String curso;
  final Turno turno;

  String get rotulo => '$curso – ${turno.rotulo}';

  Turma turma(int semestre) => Turma(curso: curso, turno: turno, semestre: semestre);
}

/// O que o aluno vê ao abrir a grade de uma turma.
sealed class ResultadoDaTurma {
  const ResultadoDaTurma();
}

class AulasDaTurma extends ResultadoDaTurma {
  const AulasDaTurma({
    required this.semestreLetivo,
    required this.semana,
    required this.horas,
    required this.disciplinas,
    required this.hoje,
    required this.proximosDias,
  });

  final SemestreLetivo semestreLetivo;

  /// A semana da turma: de segunda a sexta, com ou sem aula, e o sábado só quando há aula nele.
  final List<DiaComAulas> semana;

  /// A régua da grade de horários: as horas cheias da primeira aula até depois do fim da última.
  final List<Horario> horas;

  /// As disciplinas da turma, sem repetição, na ordem em que aparecem na semana.
  final List<String> disciplinas;

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
  ConsultaDeGrade(this._repositorio, {required MemoriaDaTurma memoria}) : _memoria = memoria;

  final RepositorioGrade _repositorio;
  final MemoriaDaTurma _memoria;

  Future<SituacaoDaGrade> cursosDisponiveis() async {
    final grade = await _repositorio.gradeAtual();
    if (grade == null) return const GradeNaoPublicada();
    final cursos = _cursosOferecidos(grade);
    return GradePublicada(
      semestreLetivo: grade.semestreLetivo,
      cursos: cursos,
      turmaLembrada: await _turmaLembrada(grade, cursos),
    );
  }

  /// Guarda a escolha do aluno para a próxima visita e devolve a grade da turma.
  Future<ResultadoDaTurma> escolher(Turma turma, {required DateTime hoje}) async {
    try {
      await _memoria.guardar(turma);
    } catch (_) {
      // Sem onde guardar, o aluno só precisa escolher de novo na próxima visita.
    }
    return gradeDaTurma(turma, hoje: hoje);
  }

  Future<EscolhaDeTurma?> _turmaLembrada(Grade grade, List<CursoOferecido> cursos) async {
    final turma = await _lembradaSemFalhar();
    if (turma == null || !grade.aulas.any((aula) => aula.turma == turma)) return null;
    final curso = cursos.firstWhere((c) => c.turma(turma.semestre) == turma);
    return (curso: curso, semestre: turma.semestre);
  }

  /// Memória que falha conta como nada guardado.
  Future<Turma?> _lembradaSemFalhar() async {
    try {
      return await _memoria.lembrada();
    } catch (_) {
      return null;
    }
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
      horas: _horasCobertas(aulas),
      disciplinas: {
        for (final dia in porDia.values)
          for (final aula in dia.aulas) aula.disciplina,
      }.toList(),
      hoje: porDia[diaDeHoje],
      proximosDias: [
        for (final dia in diasSeguintes)
          if (porDia[dia]! case final dia when dia.aulas.isNotEmpty) dia,
      ],
    );
  }

  /// Recebe as aulas em ordem de início.
  List<Horario> _horasCobertas(List<Aula> aulas) {
    final ultimoFim = aulas.map((aula) => aula.fim).reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    final ultimaHora = ultimoFim.minuto == 0 ? ultimoFim.hora : ultimoFim.hora + 1;
    return [for (var hora = aulas.first.inicio.hora; hora <= ultimaHora; hora++) Horario(hora, 0)];
  }

  List<CursoOferecido> _cursosOferecidos(Grade grade) {
    final cursosETurnos = {for (final Aula(:turma) in grade.aulas) (turma.curso, turma.turno)};
    final cursos = [for (final (curso, turno) in cursosETurnos) CursoOferecido(curso: curso, turno: turno)];
    return cursos..sort((a, b) => a.rotulo.compareTo(b.rotulo));
  }
}
