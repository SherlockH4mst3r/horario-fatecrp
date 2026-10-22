import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/admin/painel_admin.dart';
import 'package:grade_app/admin/sessao.dart';
import 'package:grade_app/tema.dart';

Uint8List planilha(String nome) => File('test/planilhas/$nome').readAsBytesSync();

final gradeAtual = Grade(semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2), aulas: const []);

void main() {
  late RepositorioGradeEmMemoria repositorio;
  late int escolhas;

  /// Abre o painel; [arquivo] é o que o admin escolhe na janela de arquivos (`null` = desistiu).
  Future<void> abrirPainel(WidgetTester tester, {Uint8List? arquivo, bool jaEntrou = true}) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repositorio = RepositorioGradeEmMemoria(gradeAtual);
    escolhas = 0;
    final sessao = SessaoSimulada(email: 'admin@fatecrp.local', senha: 'admin123');
    if (jaEntrou) await sessao.entrar(email: 'admin@fatecrp.local', senha: 'admin123');
    await tester.pumpWidget(
      MaterialApp(
        theme: temaFatec(Brightness.light),
        home: PainelAdmin(
          sessao: sessao,
          importacao: ImportacaoDeGrade(repositorio),
          escolherPlanilha: () async {
            escolhas++;
            return arquivo;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> digitar(WidgetTester tester, String campo, String texto) =>
      tester.enterText(find.widgetWithText(TextField, campo), texto);

  Future<void> tocar(WidgetTester tester, String botao) async {
    await tester.tap(find.text(botao));
    await tester.pumpAndSettle();
  }

  Future<void> importar(WidgetTester tester, {String semestreLetivo = '2027/1'}) async {
    await digitar(tester, 'Semestre letivo', semestreLetivo);
    await tocar(tester, 'Escolher planilha .xlsx');
  }

  bool publicarHabilitado(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Publicar')).onPressed != null;

  group('entrada', () {
    testWidgets('sem sessão, o painel pede e-mail e senha', (tester) async {
      await abrirPainel(tester, jaEntrou: false);

      expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
      expect(find.text('Escolher planilha .xlsx'), findsNothing);
    });

    testWidgets('senha errada mostra erro e não abre o painel', (tester) async {
      await abrirPainel(tester, jaEntrou: false);

      await digitar(tester, 'E-mail', 'admin@fatecrp.local');
      await digitar(tester, 'Senha', 'errada');
      await tocar(tester, 'Entrar');

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.text('Escolher planilha .xlsx'), findsNothing);
    });

    testWidgets('e-mail e senha do admin abrem o painel, e sair volta para a entrada', (tester) async {
      await abrirPainel(tester, jaEntrou: false);

      await digitar(tester, 'E-mail', 'admin@fatecrp.local');
      await digitar(tester, 'Senha', 'admin123');
      await tocar(tester, 'Entrar');
      expect(find.text('Escolher planilha .xlsx'), findsOneWidget);

      await tocar(tester, 'Sair');
      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    });
  });

  group('importação', () {
    testWidgets('planilha válida mostra a prévia e, ao publicar, substitui a grade', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'));

      await importar(tester);

      expect(find.text('Prévia da grade 2027/1'), findsOneWidget);
      expect(find.text('4 aulas, sem erros'), findsOneWidget);
      expect(find.text('ADS – Noite – 1º'), findsOneWidget);
      expect(find.text('B12 · 1º andar'), findsOneWidget);
      expect(await tester.runAsync(repositorio.gradeAtual), same(gradeAtual), reason: 'a prévia não publica nada');

      await tocar(tester, 'Publicar');

      final publicada = (await tester.runAsync(repositorio.gradeAtual))!;
      expect(publicada.semestreLetivo.rotulo, '2027/1');
      expect(publicada.aulas, hasLength(4));
      expect(find.text('Grade 2027/1 publicada.'), findsOneWidget);
    });

    testWidgets('planilha com erro lista cada erro pela linha e não deixa publicar', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_com_erros.xlsx'));

      await importar(tester);

      for (final erro in [
        'Linha 2 · Sala',
        'Linha 3 · Professor',
        'Linha 4 · Dia',
        'Linha 5 · Início',
        'Linha 6 · Sala',
        'Linha 7 · Andar',
      ]) {
        expect(find.textContaining(erro), findsWidgets, reason: erro);
      }
      expect(publicarHabilitado(tester), isFalse);
      expect(await tester.runAsync(repositorio.gradeAtual), same(gradeAtual));
    });

    testWidgets('cancelar a prévia volta ao início sem mudar a grade', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'));
      await importar(tester);

      await tocar(tester, 'Cancelar');

      expect(find.text('Prévia da grade 2027/1'), findsNothing);
      expect(find.text('Escolher planilha .xlsx'), findsOneWidget);
      expect(await tester.runAsync(repositorio.gradeAtual), same(gradeAtual));
    });

    testWidgets('semestre letivo fora do formato avisa antes de pedir a planilha', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'));

      await importar(tester, semestreLetivo: '2027-1');

      expect(find.text('Use ano/período, como 2027/1.'), findsOneWidget);
      expect(escolhas, 0);
    });

    testWidgets('arquivo que não é planilha avisa, sem prévia', (tester) async {
      await abrirPainel(tester, arquivo: Uint8List.fromList('não sou uma planilha'.codeUnits));

      await importar(tester);

      expect(find.textContaining('não é uma planilha .xlsx'), findsOneWidget);
      expect(find.textContaining('Prévia da grade'), findsNothing);
    });

    testWidgets('desistir da escolha do arquivo não muda nada', (tester) async {
      await abrirPainel(tester);

      await importar(tester);

      expect(escolhas, 1);
      expect(find.textContaining('Prévia da grade'), findsNothing);
      expect(find.text('Escolher planilha .xlsx'), findsOneWidget);
    });
  });
}
