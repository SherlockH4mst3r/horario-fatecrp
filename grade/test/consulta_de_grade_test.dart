import 'package:grade/grade.dart';
import 'package:test/test.dart';

/// Consulta com memória própria, para que nenhum teste dependa de outro.
ConsultaDeGrade consultaDe(RepositorioGrade repositorio, {MemoriaDaTurma? memoria}) =>
    ConsultaDeGrade(repositorio, memoria: memoria ?? MemoriaDaTurmaEmMemoria());

void main() {
  group('cursos disponíveis', () {
    test('sem grade publicada, informa que a grade não foi publicada', () async {
      final consulta = consultaDe(RepositorioGradeEmMemoria());

      final resultado = await consulta.cursosDisponiveis();

      expect(resultado, isA<GradeNaoPublicada>());
    });

    test('lista cada curso com o turno, em ordem, e oferece do 1º ao 6º semestre', () async {
      final consulta = consultaDe(
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

  group('turma lembrada', () {
    const ads3 = Turma(curso: 'ADS', turno: Turno.noite, semestre: 3);
    const gestao2 = Turma(curso: 'Gestão Empresarial', turno: Turno.manha, semestre: 2);
    final hoje = DateTime(2026, 10, 22);
    final gradeComDuasTurmas = RepositorioGradeEmMemoria(
      Grade(
        semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
        aulas: [
          aula(semestre: 3),
          aula(curso: 'Gestão Empresarial', turno: Turno.manha, semestre: 2),
        ],
      ),
    );

    Future<String?> lembrada(ConsultaDeGrade consulta) async {
      final grade = await consulta.cursosDisponiveis() as GradePublicada;
      return switch (grade.turmaLembrada) {
        (:final curso, :final semestre) => '${curso.rotulo} $semestreº',
        null => null,
      };
    }

    test('sem escolha guardada, não há turma lembrada', () async {
      final consulta = consultaDe(gradeComDuasTurmas, memoria: MemoriaDaTurmaEmMemoria());

      expect(await lembrada(consulta), isNull);
    });

    test('a turma escolhida é lembrada na próxima visita', () async {
      final memoria = MemoriaDaTurmaEmMemoria();
      await consultaDe(gradeComDuasTurmas, memoria: memoria).escolher(ads3, hoje: hoje);

      expect(await lembrada(consultaDe(gradeComDuasTurmas, memoria: memoria)), 'ADS – Noite 3º');
    });

    test('uma nova escolha substitui a guardada', () async {
      final consulta = consultaDe(gradeComDuasTurmas, memoria: MemoriaDaTurmaEmMemoria());

      await consulta.escolher(ads3, hoje: hoje);
      await consulta.escolher(gestao2, hoje: hoje);

      expect(await lembrada(consulta), 'Gestão Empresarial – Manhã 2º');
    });

    test('escolher devolve a grade da turma', () async {
      final consulta = consultaDe(gradeComDuasTurmas, memoria: MemoriaDaTurmaEmMemoria());

      expect(await consulta.escolher(ads3, hoje: hoje), isA<AulasDaTurma>());
    });

    test('a turma guardada que não tem mais aulas na grade não é lembrada', () async {
      final memoria = MemoriaDaTurmaEmMemoria();
      await memoria.guardar(const Turma(curso: 'ADS', turno: Turno.noite, semestre: 6));

      expect(await lembrada(consultaDe(gradeComDuasTurmas, memoria: memoria)), isNull);
    });

    test('se a memória falha, não há turma lembrada e a escolha ainda mostra a grade', () async {
      final consulta = consultaDe(gradeComDuasTurmas, memoria: MemoriaQueFalha());

      expect(await lembrada(consulta), isNull);
      expect(await consulta.escolher(ads3, hoje: hoje), isA<AulasDaTurma>());
    });
  });

  group('grade da turma', () {
    const ads3 = Turma(curso: 'ADS', turno: Turno.noite, semestre: 3);
    final quinta = DateTime(2026, 10, 22);

    ConsultaDeGrade consultaCom(List<Aula> aulas) => consultaDe(
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
      final resultado = await aulasDaTurma(
        consultaCom([...aulasDeAds3, aula(semestre: 3, dia: DiaDaSemana.sexta, disciplina: 'Redes')]),
      );

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
          aula(semestre: 3, inicio: '19:00', andares: [Andar.terreo]),
          aula(semestre: 3, inicio: '20:50', fim: '22:30', andares: [Andar.terceiro]),
        ]),
      );

      expect(resultado.semana.first.aulas.map((a) => a.andares.single.rotulo), ['Térreo', '3º andar']);
    });

    test('sem grade publicada, informa que a grade não foi publicada', () async {
      final consulta = consultaDe(RepositorioGradeEmMemoria());

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
  List<Andar> andares = const [Andar.primeiro],
}) => Aula(
  turma: Turma(curso: curso, turno: turno, semestre: semestre),
  dia: dia,
  inicio: Horario.parse(inicio),
  fim: Horario.parse(fim),
  disciplina: disciplina,
  professor: professor,
  sala: sala,
  andares: andares,
);

/// Simula o navegador que bloqueia o armazenamento.
class MemoriaQueFalha implements MemoriaDaTurma {
  @override
  Future<Turma?> lembrada() async => throw Exception('armazenamento bloqueado');

  @override
  Future<void> guardar(Turma turma) async => throw Exception('armazenamento bloqueado');
}
