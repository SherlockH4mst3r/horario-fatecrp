import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/admin/correcao_de_aulas.dart';
import 'package:grade_app/tema.dart';
import 'package:grade_app/telas/avisos.dart';

Aula aula({
  DiaDaSemana dia = DiaDaSemana.segunda,
  String inicio = '19:00',
  String fim = '20:40',
  String disciplina = 'Banco de Dados',
  String sala = 'S14',
}) => Aula(
  turma: const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3),
  dia: dia,
  inicio: Horario.parse(inicio),
  fim: Horario.parse(fim),
  disciplina: disciplina,
  professor: 'Rita Alves',
  sala: sala,
  andares: const [Andar.segundo],
);

void main() {
  late RepositorioGradeEmMemoria repositorio;

  Future<void> abrir(WidgetTester tester, {List<Aula> outras = const []}) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repositorio = RepositorioGradeEmMemoria(
      Grade(
        semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
        aulas: [
          aula(),
          aula(dia: DiaDaSemana.quarta, disciplina: 'IHC', sala: 'S15'),
          ...outras,
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: temaFatec(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(child: CorrecaoDeAulas(edicao: EdicaoDeAulas(repositorio))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> digitar(WidgetTester tester, String campo, String texto) async {
    await tester.enterText(find.widgetWithText(TextField, campo), texto);
    await tester.pump();
  }

  Future<List<String>> publicadas(WidgetTester tester) async => [
    for (final aula in (await tester.runAsync(repositorio.gradeAtual))!.aulas) '${aula.disciplina} ${aula.sala}',
  ];

  Finder acaoDa(String disciplina, String acao) => find.descendant(
    of: find.ancestor(of: find.text(disciplina), matching: find.byType(ListTile)),
    matching: find.byTooltip(acao),
  );

  testWidgets('lista as aulas da turma escolhida, por dia', (tester) async {
    await abrir(tester);

    expect(find.text('ADS – Noite – 3º'), findsWidgets);
    expect(find.text('Banco de Dados'), findsOneWidget);
    expect(find.text('IHC'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Banco de Dados')).dy, lessThan(tester.getTopLeft(find.text('IHC')).dy));
  });

  testWidgets('nova aula válida entra na grade e na lista', (tester) async {
    await abrir(tester);

    await tocar(tester, find.text('Nova aula'));
    await tocar(tester, find.text('Segunda').last);
    await tocar(tester, find.text('Terça').last);
    await digitar(tester, 'Disciplina', 'Redes');
    await digitar(tester, 'Professor', 'Marco A');
    await digitar(tester, 'Sala', 'LR');
    await digitar(tester, 'Andar', '1º andar');
    await tocar(tester, find.text('Salvar'));

    expect(await publicadas(tester), contains('Redes LR'));
    expect(find.text('Redes'), findsOneWidget);
  });

  Color? corDoSnackbar(WidgetTester tester) => tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor;

  testWidgets('salvar com sucesso avisa em verde', (tester) async {
    await abrir(tester);

    await tocar(tester, acaoDa('IHC', 'Editar'));
    await digitar(tester, 'Sala', 'S16');
    await tocar(tester, find.text('Salvar'));

    expect(corDoSnackbar(tester), TipoDeAviso.sucesso.fundo);
  });

  testWidgets('estender a aula até a seguinte da turma alerta em amarelo, sem salvar', (tester) async {
    await abrir(
      tester,
      outras: [aula(inicio: '20:50', fim: '22:30', disciplina: 'Redes', sala: 'LR')],
    );

    await tocar(tester, acaoDa('Banco de Dados', 'Editar'));
    await digitar(tester, 'Fim', '21:40');
    await tocar(tester, find.text('Salvar'));

    final faixa = tester.widget<FaixaDeAviso>(find.byType(FaixaDeAviso));
    expect(faixa.tipo, TipoDeAviso.alerta);
    expect(faixa.titulo, 'Não deu para salvar. Corrija o que está marcado:');
    expect(faixa.detalhes.join(), contains('a turma ADS – Noite – 3º já tem aula nesse horário: Redes'));
    final detalhe = tester.widget<Text>(find.textContaining('a turma ADS – Noite – 3º').first).style!;
    final corrido = Theme.of(tester.element(find.byType(FaixaDeAviso))).textTheme.bodyMedium!.fontSize!;
    expect([detalhe.fontSize, detalhe.fontWeight], [corrido - 2, FontWeight.bold]);
    expect(await publicadas(tester), ['Banco de Dados S14', 'IHC S15', 'Redes LR']);
  });

  testWidgets('professor em outra aula no mesmo horário salva, com alerta amarelo', (tester) async {
    await abrir(tester);

    await tocar(tester, find.text('Nova aula'));
    await tocar(tester, find.text('3').last);
    await tocar(tester, find.text('5').last);
    await digitar(tester, 'Disciplina', 'Redes');
    await digitar(tester, 'Professor', 'Rita Alves');
    await digitar(tester, 'Sala', 'LR');
    await digitar(tester, 'Andar', '1º andar');
    await tocar(tester, find.text('Salvar'));

    expect(corDoSnackbar(tester), TipoDeAviso.alerta.fundo);
    expect(find.textContaining('Rita Alves já tem aula nesse horário'), findsOneWidget);
  });

  testWidgets('aula com problema mostra o erro no campo e não salva', (tester) async {
    await abrir(tester);

    await tocar(tester, find.text('Nova aula'));
    await tocar(tester, find.text('3').last);
    await tocar(tester, find.text('5').last);
    await digitar(tester, 'Disciplina', 'Redes');
    await digitar(tester, 'Professor', 'Marco A');
    await digitar(tester, 'Sala', 'S14');
    await digitar(tester, 'Andar', '2º andar');
    await tocar(tester, find.text('Salvar'));

    expect(find.textContaining('já tem aula nesse horário'), findsNWidgets(2), reason: 'na faixa e no campo Sala');
    expect(tester.widget<FaixaDeAviso>(find.byType(FaixaDeAviso)).tipo, TipoDeAviso.alerta);
    expect(find.text('Salvar'), findsOneWidget, reason: 'o formulário continua aberto');
    expect(await publicadas(tester), ['Banco de Dados S14', 'IHC S15']);
  });

  testWidgets('editar parte da aula como está e salva a mudança', (tester) async {
    await abrir(tester);

    await tocar(tester, acaoDa('IHC', 'Editar'));
    expect(find.widgetWithText(TextField, 'S15'), findsOneWidget);
    await digitar(tester, 'Sala', 'S16');
    await tocar(tester, find.text('Salvar'));

    expect(await publicadas(tester), ['Banco de Dados S14', 'IHC S16']);
  });

  testWidgets('excluir pede confirmação antes de apagar', (tester) async {
    await abrir(tester);

    await tocar(tester, acaoDa('IHC', 'Excluir'));
    await tocar(tester, find.text('Cancelar'));
    expect(await publicadas(tester), ['Banco de Dados S14', 'IHC S15']);

    await tocar(tester, acaoDa('IHC', 'Excluir'));
    await tocar(tester, find.widgetWithText(FilledButton, 'Excluir'));
    expect(await publicadas(tester), ['Banco de Dados S14']);
    expect(find.text('IHC'), findsNothing);
  });
}
