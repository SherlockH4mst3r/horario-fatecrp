import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/main.dart';
import 'package:grade_app/preferencia_de_tema.dart';
import 'package:grade_app/tema.dart';

void main() {
  Future<void> abrirSite(WidgetTester tester, PreferenciaDeTema preferencia) async {
    await tester.pumpWidget(
      AppDaGrade(
        consulta: ConsultaDeGrade(RepositorioGradeEmMemoria(), memoria: MemoriaDaTurmaEmMemoria()),
        preferenciaDeTema: preferencia,
      ),
    );
    await tester.pumpAndSettle();
  }

  ThemeData temaDaTela(WidgetTester tester) => Theme.of(tester.element(find.text('Grade ainda não publicada')));

  test('o tema claro tem fundo creme, e o escuro, fundo jeans', () {
    expect(temaFatec(Brightness.light).scaffoldBackgroundColor, fundoClaro);
    expect(temaFatec(Brightness.dark).scaffoldBackgroundColor, fundoEscuro);
  });

  testWidgets('sem escolha guardada, segue o tema do sistema', (tester) async {
    await abrirSite(tester, PreferenciaDeTemaEmMemoria());

    expect(temaDaTela(tester).brightness, Brightness.light);
  });

  testWidgets('o botão do cabeçalho troca de tema, e a escolha fica guardada', (tester) async {
    final preferencia = PreferenciaDeTemaEmMemoria();
    await abrirSite(tester, preferencia);

    await tester.tap(find.byTooltip('Usar o tema escuro'));
    await tester.pumpAndSettle();

    expect(temaDaTela(tester).brightness, Brightness.dark);
    expect(temaDaTela(tester).scaffoldBackgroundColor, fundoEscuro);
    expect(await tester.runAsync(preferencia.lida), ThemeMode.dark);

    await tester.tap(find.byTooltip('Usar o tema claro'));
    await tester.pumpAndSettle();
    expect(temaDaTela(tester).brightness, Brightness.light);
  });

  testWidgets('ao reabrir, o site usa o tema guardado', (tester) async {
    final preferencia = PreferenciaDeTemaEmMemoria();
    await tester.runAsync(() => preferencia.guardar(ThemeMode.dark));

    await abrirSite(tester, preferencia);

    expect(temaDaTela(tester).brightness, Brightness.dark);
  });
}
