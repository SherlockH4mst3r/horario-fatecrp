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
      final consulta = ConsultaDeGrade(
        RepositorioGradeEmMemoria(
          Grade(
            semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
            aulas: [
              aula(curso: 'Gestão Empresarial', turno: Turno.manha, semestre: 2),
              aula(curso: 'ADS', turno: Turno.noite, semestre: 3),
              aula(curso: 'ADS', turno: Turno.noite, semestre: 1),
              aula(curso: 'ADS', turno: Turno.noite, semestre: 1),
            ],
          ),
        ),
      );

      final resultado = await consulta.cursosDisponiveis() as GradePublicada;

      expect(resultado.semestreLetivo.rotulo, '2026/2');
      expect(resultado.cursos.map((c) => c.rotulo), ['ADS – Noite', 'Gestão Empresarial – Manhã']);
      expect(resultado.semestres, [1, 2, 3, 4, 5, 6]);
    });
  });

  group('grade da turma', () {
    const ads3 = Turma(curso: 'ADS', turno: Turno.noite, semestre: 3);
    final quinta = DateTime(2026, 10, 22);

    ConsultaDeGrade consultaCom(List<Aula> aulas) => ConsultaDeGrade(
      RepositorioGradeEmMemoria(Grade(semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2), aulas: aulas)),
    );

    Future<AulasDaTurma> aulasDaTurma(ConsultaDeGrade consulta, {DateTime? hoje}) async =>
        await consulta.gradeDaTurma(ads3, hoje: hoje ?? quinta) as AulasDaTurma;

    List<String> resumo(List<DiaComAulas> dias) => [
      for (final DiaComAulas(:dia, :aulas) in dias)
        '${dia.rotulo}: ${aulas.map((a) => '${a.inicio} ${a.disciplina}').join(', ')}',
    ];

    final aulasDeAds3 = [
      aula(semestre: 3, dia: DiaDaSemana.quarta, inicio: '19:00', disciplina: 'Banco de Dados'),
      aula(semestre: 3, dia: DiaDaSemana.segunda, inicio: '20:50', fim: '22:30', disciplina: 'Redes'),
      aula(semestre: 1, dia: DiaDaSemana.segunda, inicio: '19:00', disciplina: 'Algoritmos'),
      aula(semestre: 3, dia: DiaDaSemana.segunda, inicio: '19:00', disciplina: 'Engenharia de Software'),
    ];

    test('a semana vai de segunda a sexta, só com as aulas da turma, em ordem de início', () async {
      final resultado = await aulasDaTurma(consultaCom(aulasDeAds3));

      expect(resultado.semestreLetivo.rotulo, '2026/2');
      expect(resumo(resultado.semana), [
        'Segunda: 19:00 Engenharia de Software, 20:50 Redes',
        'Terça: ',
        'Quarta: 19:00 Banco de Dados',
        'Quinta: ',
        'Sexta: ',
      ]);
    });

    test('o sábado entra na semana quando a turma tem aula nele', () async {
      final resultado = await aulasDaTurma(
        consultaCom([aula(semestre: 3, dia: DiaDaSemana.sabado, inicio: '08:00', disciplina: 'Projeto Integrador')]),
      );

      expect(resultado.semana.map((d) => d.dia).last, DiaDaSemana.sabado);
    });

    test('as horas da grade vão da hora cheia antes da primeira aula à hora cheia depois da última', () async {
      final resultado = await aulasDaTurma(consultaCom(aulasDeAds3));

      expect(resultado.horas.map((h) => '$h'), ['19:00', '20:00', '21:00', '22:00', '23:00']);
    });

    test('as disciplinas da turma aparecem uma vez, na ordem da semana', () async {
      final resultado = await aulasDaTurma(consultaCom([
        ...aulasDeAds3,
        aula(semestre: 3, dia: DiaDaSemana.sexta, disciplina: 'Redes'),
      ]));

      expect(resultado.disciplinas, ['Engenharia de Software', 'Redes', 'Banco de Dados']);
    });

    test('aulas em hora cheia não esticam a grade', () async {
      final resultado = await aulasDaTurma(consultaCom([aula(semestre: 3, inicio: '08:00', fim: '10:00')]));

      expect(resultado.horas.map((h) => '$h'), ['08:00', '09:00', '10:00']);
    });

    test('hoje traz as aulas do dia, e os próximos dias seguem a semana, só com aula', () async {
      final resultado = await aulasDaTurma(
        consultaCom(aulasDeAds3),
        hoje: DateTime(2026, 10, 21), // quarta
      );

      expect(resumo([resultado.hoje!]), ['Quarta: 19:00 Banco de Dados']);
      expect(resumo(resultado.proximosDias), ['Segunda: 19:00 Engenharia de Software, 20:50 Redes']);
    });

    test('num dia sem aula, hoje vem vazio, com os próximos dias depois', () async {
      final resultado = await aulasDaTurma(consultaCom(aulasDeAds3), hoje: quinta);

      expect(resumo([resultado.hoje!]), ['Quinta: ']);
      expect(resultado.proximosDias.map((d) => d.dia), [DiaDaSemana.segunda, DiaDaSemana.quarta]);
    });

    test('no domingo não há hoje, e os próximos dias começam na segunda', () async {
      final resultado = await aulasDaTurma(
        consultaCom([aula(semestre: 3, dia: DiaDaSemana.quarta), aula(semestre: 3, dia: DiaDaSemana.terca)]),
        hoje: DateTime(2026, 10, 25), // domingo
      );

      expect(resultado.hoje, isNull);
      expect(resultado.proximosDias.map((d) => d.dia), [DiaDaSemana.terca, DiaDaSemana.quarta]);
    });

    test('cada aula traz o andar da sala, do térreo ao 3º', () async {
      final resultado = await aulasDaTurma(
        consultaCom([
          aula(semestre: 3, inicio: '19:00', andar: Andar.terreo),
          aula(semestre: 3, inicio: '20:50', fim: '22:30', andar: Andar.terceiro),
        ]),
      );

      expect(resultado.semana.first.aulas.map((a) => a.andar.rotulo), ['Térreo', '3º andar']);
    });

    test('sem grade publicada, informa que a grade não foi publicada', () async {
      final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria());

      final resultado = await consulta.gradeDaTurma(ads3, hoje: quinta);

      expect(resultado, isA<GradeNaoPublicada>());
    });

    test('turma sem aulas informa isso, com o semestre letivo', () async {
      final resultado = await consultaCom([aula(semestre: 1)]).gradeDaTurma(ads3, hoje: quinta);

      expect(resultado, isA<TurmaSemAulas>().having((r) => r.semestreLetivo.rotulo, 'semestre letivo', '2026/2'));
    });
  });

  test('um horário sabe quantos minutos passaram desde outro', () {
    expect(Horario.parse('20:50').minutosDesde(Horario.parse('19:00')), 110);
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
}) => Aula(
  turma: Turma(curso: curso, turno: turno, semestre: semestre),
  dia: dia,
  inicio: Horario.parse(inicio),
  fim: Horario.parse(fim),
  disciplina: disciplina,
  professor: professor,
  sala: sala,
  andar: andar,
);
