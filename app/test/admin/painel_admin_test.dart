import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/admin/painel_admin.dart';
import 'package:grade_app/admin/sessao.dart';
import 'package:grade_app/leitor_de_planilha.dart';
import 'package:grade_app/tema.dart';
import 'package:grade_app/telas/avisos.dart';

Uint8List planilha(String nome) => File('test/planilhas/$nome').readAsBytesSync();

final gradeAtual = Grade(semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2), aulas: const []);

void main() {
  late RepositorioGradeEmMemoria repositorio;
  late int escolhas;
  late List<(String, Uint8List)> salvos;

  /// Abre o painel; [arquivo] é o que o admin escolhe na janela de arquivos (`null` = desistiu).
  Future<void> abrirPainel(
    WidgetTester tester, {
    Uint8List? arquivo,
    bool jaEntrou = true,
    Grade? publicada,
    RepositorioGrade? repositorioQueFalha,
  }) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repositorio = RepositorioGradeEmMemoria(publicada ?? gradeAtual);
    escolhas = 0;
    salvos = [];
    final sessao = SessaoSimulada(email: 'admin@fatecrp.local', senha: 'admin123');
    if (jaEntrou) await sessao.entrar(email: 'admin@fatecrp.local', senha: 'admin123');
    await tester.pumpWidget(
      MaterialApp(
        theme: temaFatec(Brightness.light),
        home: PainelAdmin(
          sessao: sessao,
          importacao: ImportacaoDeGrade(repositorioQueFalha ?? repositorio),
          edicao: EdicaoDeAulas(repositorioQueFalha ?? repositorio),
          escolherPlanilha: () async {
            escolhas++;
            return arquivo;
          },
          salvarPlanilha: (nome, bytes) async => salvos.add((nome, bytes)),
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

      await digitar(tester, 'Senha', 'admin123');
      await digitar(tester, 'E-mail', 'admin@fatecrp.local');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Escolher planilha .xlsx'), findsOneWidget, reason: 'Enter no e-mail também entra');

      await tocar(tester, 'Sair');
      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    });
  });

  testWidgets('o painel alterna entre importar a planilha e corrigir aulas', (tester) async {
    await abrirPainel(tester);

    await tocar(tester, 'Corrigir aulas');
    expect(find.text('Escolher planilha .xlsx'), findsNothing);
    expect(find.text('Ainda não há grade publicada. Importe uma planilha primeiro.'), findsOneWidget);

    await tocar(tester, 'Importar planilha');
    expect(find.text('Escolher planilha .xlsx'), findsOneWidget);
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
      expect(find.text('Grade 2027/1 publicada.'), findsWidgets);
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

      expect(find.textContaining('não é uma planilha .xlsx'), findsWidgets);
      expect(find.textContaining('Prévia da grade'), findsNothing);
    });

    testWidgets('desistir da escolha do arquivo não muda nada', (tester) async {
      await abrirPainel(tester);

      await importar(tester);

      expect(escolhas, 1);
      expect(find.textContaining('Prévia da grade'), findsNothing);
      expect(find.text('Escolher planilha .xlsx'), findsOneWidget);
    });

    testWidgets('a prévia mostra as aulas novas, removidas e alteradas em relação à grade publicada', (tester) async {
      Aula publicada({required DiaDaSemana dia, required String disciplina, required String sala}) => Aula(
        turma: const Turma(curso: 'ADS', turno: Turno.noite, semestre: 1),
        dia: dia,
        inicio: Horario.parse('19:00'),
        fim: Horario.parse('20:40'),
        disciplina: disciplina,
        professor: 'Ana Souza',
        sala: sala,
        andares: const [Andar.primeiro],
      );
      await abrirPainel(
        tester,
        arquivo: planilha('grade_exemplo.xlsx'),
        publicada: Grade(
          semestreLetivo: gradeAtual.semestreLetivo,
          aulas: [
            publicada(dia: DiaDaSemana.segunda, disciplina: 'Algoritmos', sala: 'B14'),
            publicada(dia: DiaDaSemana.sexta, disciplina: 'Redes', sala: 'B12'),
          ],
        ),
      );

      await importar(tester);

      expect(find.text('Novas (3)'), findsOneWidget);
      expect(find.text('Removidas (1)'), findsOneWidget);
      expect(find.text('ADS – Noite – 1º · Sexta 19:00–20:40 · Redes'), findsOneWidget);
      expect(find.text('Alteradas (1)'), findsOneWidget);
      expect(find.text('Sala: B14 → B12'), findsOneWidget);
    });

    testWidgets('planilha igual à grade publicada mostra "Nenhuma mudança"', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'));
      await importar(tester);
      await tocar(tester, 'Publicar');
      await tocar(tester, 'Importar outra planilha');

      await importar(tester);

      expect(find.text('Nenhuma mudança'), findsOneWidget);
    });

    testWidgets('a prévia avisa a troca de semestre letivo', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'));

      await importar(tester);

      expect(find.text('Semestre letivo: 2026/2 → 2027/1'), findsOneWidget);
    });

    testWidgets('se a publicação falha, o painel avisa e deixa tentar de novo', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'), repositorioQueFalha: _PublicacaoQueFalha());
      await importar(tester);

      await tocar(tester, 'Publicar');

      expect(find.textContaining('Não deu para publicar'), findsWidgets);
      expect(publicarHabilitado(tester), isTrue);
    });

    testWidgets('se a grade publicada não pode ser lida, o painel avisa em vez de mostrar a prévia', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'), repositorioQueFalha: _LeituraQueFalha());

      await importar(tester);

      expect(find.textContaining('Não deu para ler a grade publicada'), findsWidgets);
      expect(find.textContaining('Prévia da grade'), findsNothing);
    });

    Color? corDoSnackbar(WidgetTester tester) => tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor;

    testWidgets('publicar com sucesso avisa em verde', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'));
      await importar(tester);

      await tocar(tester, 'Publicar');

      expect(corDoSnackbar(tester), TipoDeAviso.sucesso.fundo);
    });

    testWidgets('falha ao publicar avisa em vermelho', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_exemplo.xlsx'), repositorioQueFalha: _PublicacaoQueFalha());
      await importar(tester);

      await tocar(tester, 'Publicar');

      expect(corDoSnackbar(tester), TipoDeAviso.erro.fundo);
    });

    testWidgets('planilha com erro alerta em amarelo, apontando também a outra linha do conflito', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_com_erros.xlsx'));

      await importar(tester);

      expect(corDoSnackbar(tester), TipoDeAviso.alerta.fundo);
      expect(find.textContaining('(conflita com a linha 6)'), findsOneWidget);
    });

    testWidgets('professor em dois lugares aparece como aviso, e a prévia pode ser publicada', (tester) async {
      await abrirPainel(tester, arquivo: planilha('grade_com_avisos.xlsx'));

      await importar(tester);

      final faixa = tester.widget<FaixaDeAviso>(find.byType(FaixaDeAviso));
      expect(faixa.tipo, TipoDeAviso.alerta);
      expect(faixa.detalhes.join(), contains('Carlos E já tem aula nesse horário'));
      expect(publicarHabilitado(tester), isTrue);
    });

    testWidgets('baixar a grade publicada entrega um .xlsx que a importação lê de volta', (tester) async {
      await abrirPainel(
        tester,
        publicada: Grade(
          semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
          aulas: [
            Aula(
              turma: const Turma(curso: 'ADS', turno: Turno.noite, semestre: 1),
              dia: DiaDaSemana.segunda,
              inicio: Horario.parse('19:00'),
              fim: Horario.parse('20:40'),
              disciplina: 'Algoritmos',
              professor: 'Ana Souza',
              sala: 'B12',
              andares: const [Andar.primeiro],
            ),
          ],
        ),
      );

      await tocar(tester, 'Baixar a grade publicada');

      final (nome, bytes) = salvos.single;
      expect(nome, 'grade_2026-2.xlsx');
      expect(lerPlanilhaXlsx(bytes).linhas.single.take(7), [
        'ADS',
        'Noite',
        '1',
        'Segunda',
        '19:00',
        '20:40',
        'Algoritmos',
      ]);
      expect(corDoSnackbar(tester), TipoDeAviso.sucesso.fundo);
    });

    testWidgets('sem grade publicada, não há o que baixar, e o painel avisa em amarelo', (tester) async {
      await abrirPainel(tester, repositorioQueFalha: _PublicacaoQueFalha());

      await tocar(tester, 'Baixar a grade publicada');

      expect(salvos, isEmpty);
      expect(corDoSnackbar(tester), TipoDeAviso.alerta.fundo);
    });

    testWidgets('se a grade publicada não pode ser lida, baixar avisa em vermelho', (tester) async {
      await abrirPainel(tester, repositorioQueFalha: _LeituraQueFalha());

      await tocar(tester, 'Baixar a grade publicada');

      expect(salvos, isEmpty);
      expect(corDoSnackbar(tester), TipoDeAviso.erro.fundo);
    });
  });
}

class _PublicacaoQueFalha implements RepositorioGrade {
  @override
  Future<Grade?> gradeAtual() async => null;

  @override
  Future<void> substituir(Grade grade) async => throw Exception('armazenamento cheio');
}

class _LeituraQueFalha implements RepositorioGrade {
  @override
  Future<Grade?> gradeAtual() async => throw const FormatException('grade ilegível');

  @override
  Future<void> substituir(Grade grade) async {}
}
