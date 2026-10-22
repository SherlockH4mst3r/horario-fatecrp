import 'package:grade/grade.dart';
import 'package:test/test.dart';

const semestreLetivo = SemestreLetivo(ano: 2027, periodo: 1);
const cabecalho = ['Curso', 'Turno', 'Semestre', 'Dia', 'Início', 'Fim', 'Disciplina', 'Professor', 'Sala', 'Andar'];

/// Uma linha da planilha, já como texto, com valores válidos por padrão.
List<String> linha({
  String curso = 'ADS',
  String turno = 'Noite',
  String semestre = '3',
  String dia = 'Segunda',
  String inicio = '19:00',
  String fim = '20:40',
  String disciplina = 'Banco de Dados',
  String professor = 'Rita Alves',
  String sala = 'Lab 1',
  String andar = '2º andar',
}) => [curso, turno, semestre, dia, inicio, fim, disciplina, professor, sala, andar];

Planilha planilha(List<List<String>> linhas, {List<String> cabecalho = cabecalho}) =>
    Planilha(cabecalho: cabecalho, linhas: linhas);

/// Cada erro como "linha coluna", ex.: "2 Sala".
List<String> erros(Previa previa) => [for (final erro in previa.erros) '${erro.linha} ${erro.coluna}'];

/// Uma aula já publicada, com valores que combinam com [linha] por padrão.
Aula aulaPublicada({
  int semestre = 3,
  DiaDaSemana dia = DiaDaSemana.segunda,
  String inicio = '19:00',
  String fim = '20:40',
  String disciplina = 'Banco de Dados',
  String professor = 'Rita Alves',
  String sala = 'Lab 1',
  List<Andar> andares = const [Andar.segundo],
}) => Aula(
  turma: Turma(curso: 'ADS', turno: Turno.noite, semestre: semestre),
  dia: dia,
  inicio: Horario.parse(inicio),
  fim: Horario.parse(fim),
  disciplina: disciplina,
  professor: professor,
  sala: sala,
  andares: andares,
);

void main() {
  late RepositorioGradeEmMemoria repositorio;
  late ImportacaoDeGrade importacao;

  setUp(() {
    repositorio = RepositorioGradeEmMemoria();
    importacao = ImportacaoDeGrade(repositorio);
  });

  group('planilha válida', () {
    test('cada linha vira uma aula do semestre letivo informado', () async {
      final previa = await importacao.importar(planilha([linha()]), semestreLetivo);
      await importacao.publicar(previa);

      final grade = (await repositorio.gradeAtual())!;
      expect(grade.semestreLetivo.rotulo, '2027/1');
      final aula = grade.aulas.single;
      expect(aula.turma, const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3));
      expect(
        [aula.dia, '${aula.inicio}', '${aula.fim}', aula.disciplina, aula.professor, aula.sala, aula.andares],
        [
          DiaDaSemana.segunda,
          '19:00',
          '20:40',
          'Banco de Dados',
          'Rita Alves',
          'Lab 1',
          [Andar.segundo],
        ],
      );
    });

    test('aceita variações de escrita em turno, dia, semestre, horário e andar', () async {
      final previa = await importacao.importar(
        planilha([
          linha(turno: 'NOITE', dia: 'terca-feira', semestre: '3º', inicio: '7:40', fim: '09:20', andar: 'terreo'),
          linha(turno: 'manhã', dia: 'Sábado', semestre: ' 1 ', inicio: '19:00:00', sala: 'A10', andar: '3'),
          linha(dia: 'terça feira', sala: 'B12', andar: '1º'),
        ]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
      await importacao.publicar(previa);
      final aulas = (await repositorio.gradeAtual())!.aulas;
      expect(aulas.map((a) => (a.turma.turno, a.dia, a.turma.semestre, '${a.inicio}', a.andares.single)), [
        (Turno.noite, DiaDaSemana.terca, 3, '07:40', Andar.terreo),
        (Turno.manha, DiaDaSemana.sabado, 1, '19:00', Andar.terceiro),
        (Turno.noite, DiaDaSemana.terca, 3, '19:00', Andar.primeiro),
      ]);
    });

    test('as colunas podem vir em qualquer ordem, com o cabeçalho sem acento', () async {
      final previa = await importacao.importar(
        planilha(
          [
            ['Lab 1', '2º andar', 'ADS', 'Noite', '3', 'Segunda', '19:00', '20:40', 'Banco de Dados', 'Rita Alves'],
          ],
          cabecalho: ['sala', 'ANDAR', 'curso', 'turno', 'semestre', 'dia', 'inicio', 'fim', 'disciplina', 'professor'],
        ),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
      expect(previa.turmas, [const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3)]);
    });

    test('linhas totalmente vazias são ignoradas', () async {
      final previa = await importacao.importar(
        planilha([linha(), List.filled(10, ''), List.filled(10, ' ')]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
      expect(previa.quantidadeDeAulas, 1);
    });

    test('a prévia lista as turmas e as salas encontradas, sem repetição e em ordem', () async {
      final previa = await importacao.importar(
        planilha([
          linha(curso: 'Gestão Empresarial', turno: 'Manhã', semestre: '2', sala: 'A10', andar: '3º andar'),
          linha(semestre: '3', sala: 'Lab 1', dia: 'Terça'),
          linha(semestre: '1', sala: 'B12', andar: '1º andar'),
          linha(semestre: '3', sala: 'Lab 1', dia: 'Quarta'),
        ]),
        semestreLetivo,
      );

      expect(previa.turmas.map((t) => '${t.curso} ${t.turno.rotulo} ${t.semestre}'), [
        'ADS Noite 1',
        'ADS Noite 3',
        'Gestão Empresarial Manhã 2',
      ]);
      expect(previa.salas.map((s) => '${s.sala} ${s.andar.rotulo}'), [
        'A10 3º andar',
        'B12 1º andar',
        'Lab 1 2º andar',
      ]);
    });

    test('salas escritas de jeitos diferentes viram salas diferentes, e a prévia mostra as duas', () async {
      final previa = await importacao.importar(
        planilha([linha(sala: 'Lab 1'), linha(dia: 'Terça', sala: 'lab 1')]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
      expect(previa.salas.map((s) => s.sala), ['Lab 1', 'lab 1']);
    });

    test('aula que alterna entre duas salas traz o andar de cada uma, na mesma ordem', () async {
      final previa = await importacao.importar(
        planilha([
          linha(sala: 'S4/L3', andar: '1º andar/3º andar'),
          linha(dia: 'Terça', sala: 'L1/S2', andar: '1º andar'),
        ]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
      await importacao.publicar(previa);
      final aulas = (await repositorio.gradeAtual())!.aulas;
      expect(aulas.map((a) => '${a.sala} ${a.andares.map((andar) => andar.rotulo).join('/')}'), [
        'S4/L3 1º andar/3º andar',
        'L1/S2 1º andar/1º andar',
      ]);
      expect(previa.salas.map((s) => '${s.sala} ${s.andar.rotulo}'), [
        'L1 1º andar',
        'L3 3º andar',
        'S2 1º andar',
        'S4 1º andar',
      ]);
    });

    test('sala a definir pode vir sem andar', () async {
      final previa = await importacao.importar(
        planilha([linha(sala: 'A definir – ADS Noite 6º', andar: '')]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
      await importacao.publicar(previa);
      expect((await repositorio.gradeAtual())!.aulas.single.andares, isEmpty);
      expect(previa.salas, isEmpty);
    });

    test('importar não altera a grade publicada; só publicar altera', () async {
      final atual = Grade(semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2), aulas: const []);
      repositorio = RepositorioGradeEmMemoria(atual);
      importacao = ImportacaoDeGrade(repositorio);

      await importacao.importar(planilha([linha()]), semestreLetivo);

      expect(await repositorio.gradeAtual(), same(atual));
    });

    test('publicar substitui a grade inteira, sem mesclar com a anterior', () async {
      repositorio = RepositorioGradeEmMemoria(
        Grade(
          semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
          aulas: [
            Aula(
              turma: const Turma(curso: 'ADS', turno: Turno.noite, semestre: 1),
              dia: DiaDaSemana.sexta,
              inicio: Horario.parse('19:00'),
              fim: Horario.parse('20:40'),
              disciplina: 'Antiga',
              professor: 'Fulano',
              sala: 'B12',
              andares: const [Andar.primeiro],
            ),
          ],
        ),
      );
      importacao = ImportacaoDeGrade(repositorio);

      await importacao.publicar(await importacao.importar(planilha([linha()]), semestreLetivo));

      final grade = (await repositorio.gradeAtual())!;
      expect(grade.semestreLetivo.rotulo, '2027/1');
      expect(grade.aulas.map((a) => a.disciplina), ['Banco de Dados']);
    });
  });

  group('planilha com erro', () {
    test('campo vazio gera erro com o número da linha e o nome da coluna', () async {
      final previa = await importacao.importar(
        planilha([linha(), linha(dia: 'Quarta', sala: ''), linha(dia: 'Terça', professor: '  ')]),
        semestreLetivo,
      );

      expect(erros(previa), ['3 Sala', '4 Professor']);
    });

    test('coluna repetida no cabeçalho gera erro na linha 1', () async {
      final previa = await importacao.importar(
        planilha(
          [
            [...linha(), 'B14'],
          ],
          cabecalho: [...cabecalho, 'sala'],
        ),
        semestreLetivo,
      );

      expect(erros(previa), ['1 Sala']);
    });

    test('coluna que falta no cabeçalho gera erro na linha 1', () async {
      final previa = await importacao.importar(
        planilha([linha().sublist(0, 9)], cabecalho: cabecalho.sublist(0, 9)),
        semestreLetivo,
      );

      expect(erros(previa), ['1 Andar']);
    });

    test('horário em formato inválido gera erro na linha', () async {
      final previa = await importacao.importar(
        planilha([linha(inicio: '19h'), linha(fim: '25:00'), linha(inicio: '19:60')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Início', '3 Fim', '4 Início']);
    });

    test('fim antes do início, ou igual a ele, gera erro na linha', () async {
      final previa = await importacao.importar(
        planilha([linha(inicio: '20:40', fim: '19:00'), linha(inicio: '19:00', fim: '19:00')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Fim', '3 Fim']);
    });

    test('dia fora de segunda a sábado, incluindo domingo, gera erro na linha', () async {
      final previa = await importacao.importar(
        planilha([linha(dia: 'Domingo'), linha(dia: 'Segundaa')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Dia', '3 Dia']);
    });

    test('turno, semestre ou andar fora dos valores possíveis geram erro na linha', () async {
      final previa = await importacao.importar(
        planilha([
          linha(dia: 'Segunda', turno: 'Madrugada'),
          linha(dia: 'Terça', semestre: '7'),
          linha(dia: 'Quarta', semestre: 'três'),
          linha(dia: 'Quinta', andar: '4º andar'),
        ]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Turno', '3 Semestre', '4 Semestre', '5 Andar']);
    });

    test('duas aulas na mesma sala, no mesmo dia e com horários sobrepostos geram erro nas duas linhas', () async {
      final previa = await importacao.importar(
        planilha([
          linha(inicio: '19:00', fim: '20:40'),
          linha(semestre: '1', dia: 'Terça'),
          linha(semestre: '5', inicio: '20:00', fim: '22:30'),
        ]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Sala', '4 Sala']);
    });

    test('o conflito de sala aparece mesmo quando a linha tem outro erro', () async {
      final previa = await importacao.importar(
        planilha([linha(), linha(semestre: '5', professor: '')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Sala', '3 Professor', '3 Sala']);
    });

    test('com erro, a prévia ainda lista as turmas e as salas das linhas legíveis', () async {
      final previa = await importacao.importar(
        planilha([linha(professor: ''), linha(curso: 'Gestão', turno: 'Manhã', sala: 'A10', inicio: '25:00')]),
        semestreLetivo,
      );

      expect(previa.turmas.map((t) => t.curso), ['ADS', 'Gestão']);
      expect(previa.salas.map((s) => s.sala), ['A10', 'Lab 1']);
    });

    test('a mesma turma com duas aulas ao mesmo tempo gera erro nas duas linhas', () async {
      final previa = await importacao.importar(
        planilha([linha(), linha(disciplina: 'Redes', inicio: '20:00', fim: '21:40', sala: 'S15')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Início', '3 Início']);
    });

    test('o conflito diz com qual aula, e em que linha, a aula se choca', () async {
      final previa = await importacao.importar(
        planilha([linha(), linha(semestre: '5', disciplina: 'Redes', inicio: '20:00', fim: '21:40')]),
        semestreLetivo,
      );

      final erro = previa.erros.first;
      expect(erro.mensagem, 'a sala Lab 1 já tem aula nesse horário: Redes, ADS – Noite – 5º, 20:00–21:40');
      expect(erro.outraLinha, 3);
    });

    test('o mesmo professor em duas aulas ao mesmo tempo é aviso, e a prévia ainda pode ser publicada', () async {
      final previa = await importacao.importar(
        planilha([linha(), linha(semestre: '5', disciplina: 'Redes', sala: 'S15')]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
      expect(previa.podePublicar, isTrue);
      expect([for (final aviso in previa.avisos) '${aviso.linha} ${aviso.coluna}'], ['2 Professor', '3 Professor']);
      expect(previa.avisos.first.mensagem, contains('Rita Alves já tem aula nesse horário: Redes'));
    });

    test('aulas na mesma sala que só se encostam não geram erro', () async {
      final previa = await importacao.importar(
        planilha([linha(inicio: '19:00', fim: '20:40'), linha(semestre: '5', inicio: '20:40', fim: '22:30')]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
    });

    test('sala conhecida sem andar gera erro de campo vazio', () async {
      final previa = await importacao.importar(planilha([linha(andar: '')]), semestreLetivo);

      expect(erros(previa), ['2 Andar']);
    });

    test('espaços em volta da barra da sala dupla não contam', () async {
      final previa = await importacao.importar(planilha([linha(sala: ' L1 / S2 ', andar: '1º andar')]), semestreLetivo);
      await importacao.publicar(previa);

      expect((await repositorio.gradeAtual())!.aulas.single.sala, 'L1/S2');
    });

    test('sala dupla com uma das salas vazia gera erro na linha', () async {
      final previa = await importacao.importar(planilha([linha(sala: 'L1/', andar: '1º andar')]), semestreLetivo);

      expect(erros(previa), ['2 Sala']);
    });

    test('número de andares diferente do número de salas gera erro na linha', () async {
      final previa = await importacao.importar(planilha([linha(sala: 'S4/L3', andar: '1º/2º/3º')]), semestreLetivo);

      expect(erros(previa), ['2 Andar']);
    });

    test('a mesma sala em andares diferentes gera erro, também quando ela aparece numa sala dupla', () async {
      final previa = await importacao.importar(
        planilha([
          linha(dia: 'Segunda', sala: 'L1/S2', andar: '1º andar'),
          linha(dia: 'Terça', sala: 'L1', andar: '2º andar'),
        ]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Andar', '3 Andar']);
    });

    test('a mesma sala com andares diferentes gera erro nessas linhas', () async {
      final previa = await importacao.importar(
        planilha([linha(dia: 'Segunda'), linha(dia: 'Terça'), linha(dia: 'Quarta', andar: 'Térreo')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Andar', '3 Andar', '4 Andar']);
    });

    test('com qualquer erro, a prévia não pode ser publicada e a grade continua a mesma', () async {
      final previa = await importacao.importar(planilha([linha(), linha(sala: '')]), semestreLetivo);

      expect(previa.podePublicar, isFalse);
      await expectLater(importacao.publicar(previa), throwsStateError);
      expect(await repositorio.gradeAtual(), isNull);
    });
  });

  group('diferenças contra a grade atual', () {
    Future<Diferencas> diferencasEntre(
      List<Aula> publicadas,
      List<List<String>> linhas, {
      SemestreLetivo publicado = semestreLetivo,
    }) async {
      repositorio = RepositorioGradeEmMemoria(Grade(semestreLetivo: publicado, aulas: publicadas));
      importacao = ImportacaoDeGrade(repositorio);
      final previa = await importacao.importar(planilha(linhas), semestreLetivo);
      expect(previa.erros, isEmpty);
      return previa.diferencas!;
    }

    String resumo(Aula aula) => '${aula.turma.semestre}º ${aula.dia.rotulo} ${aula.inicio} ${aula.disciplina}';

    test('sem grade publicada, todas as aulas são novas', () async {
      final previa = await importacao.importar(planilha([linha(), linha(dia: 'Terça')]), semestreLetivo);

      final diferencas = previa.diferencas!;
      expect(diferencas.novas.map(resumo), ['3º Segunda 19:00 Banco de Dados', '3º Terça 19:00 Banco de Dados']);
      expect([...diferencas.removidas, ...diferencas.alteradas], isEmpty);
    });

    test('planilha igual à grade atual não muda nada', () async {
      final diferencas = await diferencasEntre([aulaPublicada()], [linha()]);

      expect(diferencas.nenhuma, isTrue);
    });

    test('lista as aulas novas e as removidas', () async {
      final diferencas = await diferencasEntre(
        [aulaPublicada(), aulaPublicada(dia: DiaDaSemana.quarta, disciplina: 'Redes')],
        [linha(), linha(dia: 'Sexta', disciplina: 'IHC')],
      );

      expect(diferencas.novas.map(resumo), ['3º Sexta 19:00 IHC']);
      expect(diferencas.removidas.map(resumo), ['3º Quarta 19:00 Redes']);
      expect(diferencas.alteradas, isEmpty);
      expect(diferencas.nenhuma, isFalse);
    });

    test('mudança de sala, horário ou professor é alteração, com o valor antigo e o novo de cada campo', () async {
      final diferencas = await diferencasEntre(
        [aulaPublicada()],
        [linha(inicio: '20:50', fim: '22:30', professor: 'Ana Souza', sala: 'S14', andar: '2º andar')],
      );

      final alterada = diferencas.alteradas.single;
      expect(resumo(alterada.antes), '3º Segunda 19:00 Banco de Dados');
      expect(alterada.mudancas.map((m) => '${m.campo}: ${m.antes} → ${m.depois}'), [
        'Início: 19:00 → 20:50',
        'Fim: 20:40 → 22:30',
        'Professor: Rita Alves → Ana Souza',
        'Sala: Lab 1 → S14',
      ]);
      expect([...diferencas.novas, ...diferencas.removidas], isEmpty);
    });

    test('mudança só de andar aparece como alteração do andar', () async {
      final diferencas = await diferencasEntre([aulaPublicada()], [linha(andar: '3º andar')]);

      expect(diferencas.alteradas.single.mudancas.map((m) => '${m.campo}: ${m.antes} → ${m.depois}'), [
        'Andar: 2º andar → 3º andar',
      ]);
    });

    test('outra turma, disciplina ou dia é outra aula, não alteração', () async {
      final diferencas = await diferencasEntre([aulaPublicada()], [linha(semestre: '4')]);

      expect(diferencas.novas.map(resumo), ['4º Segunda 19:00 Banco de Dados']);
      expect(diferencas.removidas.map(resumo), ['3º Segunda 19:00 Banco de Dados']);
      expect(diferencas.alteradas, isEmpty);
    });

    test('troca de semestre letivo é uma mudança, mesmo com as mesmas aulas', () async {
      final diferencas = await diferencasEntre(
        [aulaPublicada()],
        [linha()],
        publicado: const SemestreLetivo(ano: 2026, periodo: 2),
      );

      expect(diferencas.nenhuma, isFalse);
      expect(
        '${diferencas.semestreLetivo!.antes.rotulo} → ${diferencas.semestreLetivo!.depois.rotulo}',
        '2026/2 → 2027/1',
      );
    });

    test('mesmo semestre letivo não aparece como mudança', () async {
      final diferencas = await diferencasEntre([aulaPublicada()], [linha()]);

      expect(diferencas.semestreLetivo, isNull);
    });

    test('se uma das duas aulas da disciplina no dia sai, a que fica não aparece alterada', () async {
      final diferencas = await diferencasEntre(
        [aulaPublicada(inicio: '07:40', fim: '09:20'), aulaPublicada(inicio: '11:20', fim: '13:00')],
        [linha(inicio: '11:20', fim: '13:00')],
      );

      expect(diferencas.alteradas, isEmpty);
      expect(diferencas.removidas.map(resumo), ['3º Segunda 07:40 Banco de Dados']);
    });

    test('a mesma disciplina duas vezes no dia é emparelhada pela ordem de início', () async {
      final diferencas = await diferencasEntre(
        [aulaPublicada(inicio: '07:40', fim: '09:20'), aulaPublicada(inicio: '11:20', fim: '13:00')],
        [linha(inicio: '07:40', fim: '09:20'), linha(inicio: '11:20', fim: '13:00', sala: 'S14')],
      );

      final alterada = diferencas.alteradas.single;
      expect('${alterada.antes.inicio}', '11:20');
      expect(alterada.mudancas.map((m) => m.campo), ['Sala']);
      expect([...diferencas.novas, ...diferencas.removidas], isEmpty);
    });

    test('com erro na planilha, a prévia não calcula as diferenças', () async {
      final previa = await importacao.importar(planilha([linha(sala: '')]), semestreLetivo);

      expect(previa.diferencas, isNull);
    });
  });

  group('exportação', () {
    test('sem grade publicada, não há o que exportar', () async {
      expect(await importacao.exportar(), isNull);
    });

    test('a grade publicada vira planilha com as colunas da importação, por turma, dia e início', () async {
      repositorio = RepositorioGradeEmMemoria(
        Grade(
          semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
          aulas: [
            aulaPublicada(
              semestre: 5,
              dia: DiaDaSemana.terca,
              sala: 'L1/S2',
              andares: const [Andar.primeiro, Andar.primeiro],
            ),
            aulaPublicada(dia: DiaDaSemana.quarta, disciplina: 'Redes'),
            aulaPublicada(sala: 'A definir – ADS Noite 3º', andares: const []),
          ],
        ),
      );
      importacao = ImportacaoDeGrade(repositorio);

      final exportada = (await importacao.exportar())!;

      expect(exportada.semestreLetivo.rotulo, '2026/2');
      expect(exportada.planilha.cabecalho, colunasDaPlanilha);
      expect(exportada.planilha.linhas, [
        [
          'ADS',
          'Noite',
          '3',
          'Segunda',
          '19:00',
          '20:40',
          'Banco de Dados',
          'Rita Alves',
          'A definir – ADS Noite 3º',
          '',
        ],
        ['ADS', 'Noite', '3', 'Quarta', '19:00', '20:40', 'Redes', 'Rita Alves', 'Lab 1', '2º andar'],
        ['ADS', 'Noite', '5', 'Terça', '19:00', '20:40', 'Banco de Dados', 'Rita Alves', 'L1/S2', '1º andar/1º andar'],
      ]);
    });

    test('importar a planilha exportada não muda nada', () async {
      repositorio = RepositorioGradeEmMemoria(
        Grade(
          semestreLetivo: semestreLetivo,
          aulas: [
            aulaPublicada(),
            aulaPublicada(semestre: 4, sala: 'S4/L3', andares: const [Andar.primeiro, Andar.terceiro]),
            aulaPublicada(semestre: 6, sala: 'A definir – ADS Noite 6º', andares: const []),
          ],
        ),
      );
      importacao = ImportacaoDeGrade(repositorio);

      final exportada = (await importacao.exportar())!;
      final previa = await importacao.importar(exportada.planilha, exportada.semestreLetivo);

      expect(previa.erros, isEmpty);
      expect(previa.diferencas!.nenhuma, isTrue);
    });
  });
}
