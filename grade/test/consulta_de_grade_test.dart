import 'package:grade/grade.dart';
import 'package:test/test.dart';

void main() {
  group('cursos disponíveis', () {
    test('sem grade publicada, informa que a grade não foi publicada', () async {
      final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria());

      final resultado = await consulta.cursosDisponiveis();

      expect(resultado, isA<GradeNaoPublicada>());
    });

    test('lista cada curso com o turno, em ordem, e oferece do 1º ao 6º semestre', () async {
      final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria(Grade(
        semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
        aulas: [
          aula(curso: 'Gestão Empresarial', turno: Turno.manha, semestre: 2),
          aula(curso: 'ADS', turno: Turno.noite, semestre: 3),
          aula(curso: 'ADS', turno: Turno.noite, semestre: 1),
          aula(curso: 'ADS', turno: Turno.noite, semestre: 1),
        ],
      )));

      final resultado = await consulta.cursosDisponiveis() as GradePublicada;

      expect(resultado.semestreLetivo.rotulo, '2026/2');
      expect(resultado.cursos.map((c) => c.rotulo), ['ADS – Noite', 'Gestão Empresarial – Manhã']);
      expect(resultado.semestres, [1, 2, 3, 4, 5, 6]);
    });
  });

  group('grade da turma', () {
    const ads3 = Turma(curso: 'ADS', turno: Turno.noite, semestre: 3);

    test('mostra só as aulas da turma, agrupadas por dia e em ordem de início', () async {
      final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria(Grade(
        semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
        aulas: [
          aula(semestre: 3, dia: DiaDaSemana.quarta, inicio: '19:00', disciplina: 'Banco de Dados'),
          aula(semestre: 3, dia: DiaDaSemana.segunda, inicio: '20:50', fim: '22:30', disciplina: 'Redes'),
          aula(semestre: 1, dia: DiaDaSemana.segunda, inicio: '19:00', disciplina: 'Algoritmos'),
          aula(semestre: 3, dia: DiaDaSemana.segunda, inicio: '19:00', disciplina: 'Engenharia de Software'),
        ],
      )));

      final resultado = await consulta.gradeDaTurma(ads3) as AulasDaTurma;

      expect(resultado.semestreLetivo.rotulo, '2026/2');
      expect(
        resultado.dias.map((d) => '${d.dia.rotulo}: ${d.aulas.map((a) => '${a.inicio} ${a.disciplina}').join(', ')}'),
        [
          'Segunda: 19:00 Engenharia de Software, 20:50 Redes',
          'Quarta: 19:00 Banco de Dados',
        ],
      );
    });

    test('cada aula traz o andar da sala, do térreo ao 3º', () async {
      final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria(Grade(
        semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
        aulas: [
          aula(semestre: 3, inicio: '19:00', andar: Andar.terreo),
          aula(semestre: 3, inicio: '20:50', fim: '22:30', andar: Andar.terceiro),
        ],
      )));

      final resultado = await consulta.gradeDaTurma(ads3) as AulasDaTurma;

      expect(resultado.dias.single.aulas.map((a) => a.andar.rotulo), ['Térreo', '3º andar']);
    });

    test('sem grade publicada, informa que a grade não foi publicada', () async {
      final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria());

      final resultado = await consulta.gradeDaTurma(ads3);

      expect(resultado, isA<GradeNaoPublicada>());
    });

    test('turma sem aulas informa isso, com o semestre letivo', () async {
      final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria(Grade(
        semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
        aulas: [aula(semestre: 1)],
      )));

      final resultado = await consulta.gradeDaTurma(ads3);

      expect(resultado, isA<TurmaSemAulas>().having((r) => r.semestreLetivo.rotulo, 'semestre letivo', '2026/2'));
    });
  });
}

Aula aula({
  String curso = 'ADS',
  Turno turno = Turno.noite,
  int semestre = 1,
  DiaDaSemana dia = DiaDaSemana.segunda,
  String inicio = '19:00',
  String fim = '20:40',
  String disciplina = 'Algoritmos',
  String professor = 'Ana Souza',
  String sala = 'B12',
  Andar andar = Andar.primeiro,
}) =>
    Aula(
      turma: Turma(curso: curso, turno: turno, semestre: semestre),
      dia: dia,
      inicio: Horario.parse(inicio),
      fim: Horario.parse(fim),
      disciplina: disciplina,
      professor: professor,
      sala: sala,
      andar: andar,
    );
