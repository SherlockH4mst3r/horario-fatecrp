import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/grade_semeada.dart';
import 'package:grade_app/main.dart';

void main() {
  Future<void> abrirSite(WidgetTester tester, [Grade? grade]) async {
    await tester.pumpWidget(AppDaGrade(consulta: ConsultaDeGrade(RepositorioGradeEmMemoria(grade))));
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
    await abrirSite(tester, gradeSemeada);

    expect(find.text('Grade 2026/2'), findsOneWidget);

    await abrirMenu(tester, 'Curso');
    expect(find.text('ADS – Noite'), findsWidgets);
    expect(find.text('Gestão Empresarial – Manhã'), findsWidgets);
  });

  testWidgets('oferece do 1º ao 6º semestre', (tester) async {
    await abrirSite(tester, gradeSemeada);
    await escolher(tester, 'Curso', 'ADS – Noite');

    await abrirMenu(tester, 'Semestre');
    for (final s in ['1º', '2º', '3º', '4º', '5º', '6º']) {
      expect(find.text(s), findsWidgets);
    }
  });

  testWidgets('cada aula mostra disciplina, professor, sala, início e fim', (tester) async {
    await abrirSite(tester, gradeSemeada);
    await escolher(tester, 'Curso', 'ADS – Noite');
    await escolher(tester, 'Semestre', '3º');

    expect(find.text('Quarta'), findsOneWidget);
    expect(find.text('Banco de Dados'), findsOneWidget);
    expect(find.text('Rita Alves'), findsOneWidget);
    expect(find.text('Sala Lab 1'), findsOneWidget);
    expect(find.text('19:00\n22:30'), findsOneWidget);
  });

  testWidgets('turma sem aulas mostra mensagem própria', (tester) async {
    await abrirSite(tester, gradeSemeada);
    await escolher(tester, 'Curso', 'ADS – Noite');
    await escolher(tester, 'Semestre', '6º');

    expect(find.text('Esta turma não tem aulas nesta grade.'), findsOneWidget);
  });

  testWidgets('sem grade, mostra "Grade ainda não publicada"', (tester) async {
    await abrirSite(tester);

    expect(find.text('Grade ainda não publicada'), findsOneWidget);
  });
}
