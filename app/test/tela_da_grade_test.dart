import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/main.dart';

/// Grade própria dos testes, para não depender da grade semeada do app.
final grade = Grade(
  semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
  aulas: [
    aula(curso: 'ADS', turno: Turno.noite, semestre: 3, dia: DiaDaSemana.quarta, disciplina: 'Banco de Dados'),
    aula(curso: 'Gestão Empresarial', turno: Turno.manha, semestre: 2),
  ],
);

/// A mesma grade, com uma aula de ADS 3º no sábado.
final gradeComSabado = Grade(
  semestreLetivo: grade.semestreLetivo,
  aulas: [
    ...grade.aulas,
    aula(curso: 'ADS', turno: Turno.noite, semestre: 3, dia: DiaDaSemana.sabado, disciplina: 'Projeto Integrador'),
  ],
);

Aula aula({
  required String curso,
  required Turno turno,
  required int semestre,
  DiaDaSemana dia = DiaDaSemana.segunda,
  String disciplina = 'Contabilidade',
  String inicio = '19:00',
  String fim = '22:30',
  String sala = 'Lab 1',
  List<Andar> andares = const [Andar.segundo],
}) => Aula(
  turma: Turma(curso: curso, turno: turno, semestre: semestre),
  dia: dia,
  inicio: Horario.parse(inicio),
  fim: Horario.parse(fim),
  disciplina: disciplina,
  professor: 'Rita Alves',
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

/// Simula a falha do banco ao buscar a grade.
class RepositorioQueFalha implements RepositorioGrade {
  @override
  Future<Grade?> gradeAtual() async => throw Exception('banco fora do ar');

  @override
  Future<void> substituir(Grade grade) async => throw Exception('banco fora do ar');
}

void main() {
  /// Abre o site numa quinta, salvo outra data.
  Future<void> abrirSite(
    WidgetTester tester,
    RepositorioGrade repositorio, {
    DateTime? em,
    MemoriaDaTurma? memoria,
  }) async {
    final hoje = em ?? DateTime(2026, 10, 22);
    await tester.pumpWidget(
      AppDaGrade(
        consulta: ConsultaDeGrade(repositorio, memoria: memoria ?? MemoriaDaTurmaEmMemoria()),
        relogio: () => hoje,
      ),
    );
    await tester.pumpAndSettle();
  }

  void usarTela(WidgetTester tester, double largura, double altura) {
    tester.view.physicalSize = Size(largura, altura);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  // Toca no menu, não no rótulo: o DropdownMenu desenha o rótulo duas vezes, uma delas fora do alvo.
  Future<void> abrirMenu(WidgetTester tester, String campo) async {
    await tester.tap(
      find.ancestor(of: find.text(campo).first, matching: find.byWidgetPredicate((w) => w is DropdownMenu)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> escolher(WidgetTester tester, String campo, String opcao) async {
    await abrirMenu(tester, campo);
    await tester.tap(find.text(opcao).last);
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o semestre letivo no topo e os cursos com o turno', (tester) async {
    await abrirSite(tester, RepositorioGradeEmMemoria(grade));

    expect(find.text('Grade 2026/2'), findsOneWidget);

    await abrirMenu(tester, 'Curso');
    expect(find.text('ADS – Noite'), findsWidgets);
    expect(find.text('Gestão Empresarial – Manhã'), findsWidgets);
  });

  testWidgets('oferece do 1º ao 6º semestre', (tester) async {
    await abrirSite(tester, RepositorioGradeEmMemoria(grade));
    await escolher(tester, 'Curso', 'ADS – Noite');

    await abrirMenu(tester, 'Semestre');
    for (final s in ['1º', '2º', '3º', '4º', '5º', '6º']) {
      expect(find.text(s), findsWidgets);
    }
  });

  testWidgets('cada aula mostra disciplina, professor, sala com andar, início e fim', (tester) async {
    await abrirSite(tester, RepositorioGradeEmMemoria(grade));
    await escolher(tester, 'Curso', 'ADS – Noite');
    await escolher(tester, 'Semestre', '3º');

    expect(find.text('Quarta'), findsOneWidget);
    expect(find.text('Banco de Dados'), findsOneWidget);
    expect(find.text('Rita Alves'), findsOneWidget);
    expect(find.text('Sala Lab 1 · 2º andar'), findsOneWidget);
    expect(find.text('19:00\n22:30'), findsOneWidget);
  });

  testWidgets('turma sem aulas mostra mensagem própria', (tester) async {
    await abrirSite(tester, RepositorioGradeEmMemoria(grade));
    await escolher(tester, 'Curso', 'ADS – Noite');
    await escolher(tester, 'Semestre', '6º');

    expect(find.text('Esta turma não tem aulas nesta grade.'), findsOneWidget);
  });

  testWidgets('sem grade, mostra "Grade ainda não publicada"', (tester) async {
    await abrirSite(tester, RepositorioGradeEmMemoria());

    expect(find.text('Grade ainda não publicada'), findsOneWidget);
  });

  testWidgets('se a grade não carrega, avisa em vez de girar para sempre', (tester) async {
    await abrirSite(tester, RepositorioQueFalha());

    expect(find.text('Não foi possível carregar a grade. Tente recarregar a página.'), findsOneWidget);
  });

  group('no celular', () {
    testWidgets('a lista abre na quinta (hoje), sem aulas, e segue a semana', (tester) async {
      usarTela(tester, 360, 740);
      await abrirSite(tester, RepositorioGradeEmMemoria(grade));
      await escolher(tester, 'Curso', 'ADS – Noite');
      await escolher(tester, 'Semestre', '3º');

      expect(find.text('Sem aulas hoje'), findsOneWidget);
      final topo = [
        for (final texto in ['Quinta · hoje', 'Sem aulas hoje', 'Quarta']) tester.getTopLeft(find.text(texto)).dy,
      ];
      expect(topo, orderedEquals([...topo]..sort()));
    });
  });

  testWidgets('no celular, no domingo, a lista começa na segunda sem marcar hoje', (tester) async {
    usarTela(tester, 360, 740);
    await abrirSite(tester, RepositorioGradeEmMemoria(grade), em: DateTime(2026, 10, 25));
    await escolher(tester, 'Curso', 'ADS – Noite');
    await escolher(tester, 'Semestre', '3º');

    expect(find.textContaining('hoje'), findsNothing);
    expect(find.text('Quarta'), findsOneWidget);
  });

  group('no computador', () {
    testWidgets('a grade é uma tabela de dias × horários, com o sábado quando há aula', (tester) async {
      usarTela(tester, 1280, 800);
      await abrirSite(tester, RepositorioGradeEmMemoria(gradeComSabado));
      await escolher(tester, 'Curso', 'ADS – Noite');
      await escolher(tester, 'Semestre', '3º');

      final dias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
      final cantos = [for (final dia in dias) tester.getTopLeft(find.text(dia))];
      expect(cantos.map((c) => c.dy).toSet(), hasLength(1), reason: 'os dias ficam lado a lado');
      expect(cantos.map((c) => c.dx), orderedEquals([...cantos.map((c) => c.dx)]..sort()));
      expect(find.text('Banco de Dados'), findsOneWidget);
      expect(find.text('Sem aulas hoje'), findsNothing);
    });

    testWidgets('turma sem aula no sábado não mostra a coluna', (tester) async {
      usarTela(tester, 1280, 800);
      await abrirSite(tester, RepositorioGradeEmMemoria(grade));
      await escolher(tester, 'Curso', 'Gestão Empresarial – Manhã');
      await escolher(tester, 'Semestre', '2º');

      expect(find.text('Sexta'), findsOneWidget);
      expect(find.text('Sábado'), findsNothing);
    });

    testWidgets('cada aula ocupa a altura do início ao fim', (tester) async {
      usarTela(tester, 1280, 800);
      await abrirSite(
        tester,
        RepositorioGradeEmMemoria(
          Grade(
            semestreLetivo: grade.semestreLetivo,
            aulas: [
              for (final (dia, inicio, fim, disciplina) in [
                (DiaDaSemana.segunda, '19:00', '20:40', 'Algoritmos'),
                (DiaDaSemana.segunda, '20:50', '22:30', 'Matemática Discreta'),
                (DiaDaSemana.terca, '19:00', '22:30', 'Lógica de Programação'),
              ])
                aula(
                  curso: 'ADS',
                  turno: Turno.noite,
                  semestre: 1,
                  dia: dia,
                  inicio: inicio,
                  fim: fim,
                  disciplina: disciplina,
                ),
            ],
          ),
        ),
      );
      await escolher(tester, 'Curso', 'ADS – Noite');
      await escolher(tester, 'Semestre', '1º');

      Rect bloco(String disciplina) =>
          tester.getRect(find.ancestor(of: find.text(disciplina), matching: find.byType(Card)));
      final longa = bloco('Lógica de Programação');
      expect(longa.top, moreOrLessEquals(bloco('Algoritmos').top, epsilon: 0.5));
      expect(longa.bottom, moreOrLessEquals(bloco('Matemática Discreta').bottom, epsilon: 0.5));
      expect(bloco('Algoritmos').bottom, lessThan(bloco('Matemática Discreta').top));
    });
  });

  for (final (tela, largura) in [('computador', 1280.0), ('celular', 360.0)]) {
    testWidgets('no $tela, cada disciplina tem sua cor, a mesma em todas as aulas dela', (tester) async {
      usarTela(tester, largura, 2000);
      await abrirSite(
        tester,
        RepositorioGradeEmMemoria(
          Grade(
            semestreLetivo: grade.semestreLetivo,
            aulas: [
              for (final (dia, inicio, disciplina) in [
                (DiaDaSemana.segunda, '19:00', 'Algoritmos'),
                (DiaDaSemana.segunda, '20:50', 'Matemática Discreta'),
                (DiaDaSemana.quarta, '19:00', 'Algoritmos'),
              ])
                aula(
                  curso: 'ADS',
                  turno: Turno.noite,
                  semestre: 1,
                  dia: dia,
                  inicio: inicio,
                  fim: '20:40',
                  disciplina: disciplina,
                ),
            ],
          ),
        ),
      );
      await escolher(tester, 'Curso', 'ADS – Noite');
      await escolher(tester, 'Semestre', '1º');

      List<Color?> cores(String disciplina) => [
        for (final card in tester.widgetList<Card>(
          find.ancestor(of: find.text(disciplina), matching: find.byType(Card)),
        ))
          card.color,
      ];
      final algoritmos = cores('Algoritmos');
      expect(algoritmos, hasLength(2));
      expect(algoritmos.toSet(), hasLength(1));
      expect(cores('Matemática Discreta').single, isNot(algoritmos.first));
    });
  }

  group('turma lembrada', () {
    const ads3 = Turma(curso: 'ADS', turno: Turno.noite, semestre: 3);

    testWidgets('ao reabrir o site, a grade da última turma aparece sem passar pelo seletor', (tester) async {
      final memoria = MemoriaDaTurmaEmMemoria();
      await memoria.guardar(ads3);

      await abrirSite(tester, RepositorioGradeEmMemoria(grade), memoria: memoria);

      expect(find.text('Banco de Dados'), findsOneWidget);
      final campos = tester.widgetList<TextField>(find.byType(TextField)).map((campo) => campo.controller?.text);
      expect(campos, ['ADS – Noite', '3º']);
    });

    testWidgets('a turma escolhida fica guardada', (tester) async {
      final memoria = MemoriaDaTurmaEmMemoria();
      await abrirSite(tester, RepositorioGradeEmMemoria(grade), memoria: memoria);

      await escolher(tester, 'Curso', 'ADS – Noite');
      await escolher(tester, 'Semestre', '3º');

      expect(await tester.runAsync(memoria.lembrada), ads3);
    });

    testWidgets('se o navegador bloqueia o armazenamento, o site abre no seletor sem erro', (tester) async {
      await abrirSite(tester, RepositorioGradeEmMemoria(grade), memoria: MemoriaQueFalha());

      expect(find.text('Curso'), findsWidgets);
      expect(find.text('Banco de Dados'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('sala dupla mostra os dois andares; andar repetido e sala a definir aparecem sem sobra', (tester) async {
    await abrirSite(
      tester,
      RepositorioGradeEmMemoria(
        Grade(
          semestreLetivo: grade.semestreLetivo,
          aulas: [
            for (final (dia, sala, andares) in [
              (DiaDaSemana.segunda, 'S4/L3', [Andar.primeiro, Andar.terceiro]),
              (DiaDaSemana.terca, 'L1/S2', [Andar.primeiro, Andar.primeiro]),
              (DiaDaSemana.quarta, 'A definir – ADS Noite 1º', <Andar>[]),
            ])
              aula(curso: 'ADS', turno: Turno.noite, semestre: 1, dia: dia, sala: sala, andares: andares),
          ],
        ),
      ),
    );
    await escolher(tester, 'Curso', 'ADS – Noite');
    await escolher(tester, 'Semestre', '1º');

    expect(find.text('Sala S4/L3 · 1º andar/3º andar'), findsOneWidget);
    expect(find.text('Sala L1/S2 · 1º andar'), findsOneWidget);
    expect(find.text('Sala A definir – ADS Noite 1º'), findsOneWidget);
  });
}
