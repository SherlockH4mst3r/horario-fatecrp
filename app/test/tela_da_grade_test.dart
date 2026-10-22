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

Aula aula({
  required String curso,
  required Turno turno,
  required int semestre,
  DiaDaSemana dia = DiaDaSemana.segunda,
  String disciplina = 'Contabilidade',
}) => Aula(
  turma: Turma(curso: curso, turno: turno, semestre: semestre),
  dia: dia,
  inicio: Horario.parse('19:00'),
  fim: Horario.parse('22:30'),
  disciplina: disciplina,
  professor: 'Rita Alves',
  sala: 'Lab 1',
  andar: Andar.segundo,
);

/// Simula a falha do banco ao buscar a grade.
class RepositorioQueFalha implements RepositorioGrade {
  @override
  Future<Grade?> gradeAtual() async => throw Exception('banco fora do ar');
}

void main() {
  Future<void> abrirSite(WidgetTester tester, RepositorioGrade repositorio) async {
    await tester.pumpWidget(AppDaGrade(consulta: ConsultaDeGrade(repositorio)));
    await tester.pumpAndSettle();
  }

  // O rótulo do DropdownMenu aparece duas vezes na árvore; qualquer uma abre o menu.
  Future<void> abrirMenu(WidgetTester tester, String campo) async {
    await tester.tap(find.text(campo).first);
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
}
