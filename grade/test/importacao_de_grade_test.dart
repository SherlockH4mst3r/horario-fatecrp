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

void main() {
  late RepositorioGradeEmMemoria repositorio;
  late ImportacaoDeGrade importacao;

  setUp(() {
    repositorio = RepositorioGradeEmMemoria();
    importacao = ImportacaoDeGrade(repositorio);
  });

  group('planilha válida', () {
    test('cada linha vira uma aula do semestre letivo informado', () async {
      final previa = importacao.importar(planilha([linha()]), semestreLetivo);
      await importacao.publicar(previa);

      final grade = (await repositorio.gradeAtual())!;
      expect(grade.semestreLetivo.rotulo, '2027/1');
      final aula = grade.aulas.single;
      expect(aula.turma, const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3));
      expect(
        [aula.dia, '${aula.inicio}', '${aula.fim}', aula.disciplina, aula.professor, aula.sala, aula.andar],
        [DiaDaSemana.segunda, '19:00', '20:40', 'Banco de Dados', 'Rita Alves', 'Lab 1', Andar.segundo],
      );
    });

    test('aceita variações de escrita em turno, dia, semestre, horário e andar', () async {
      final previa = importacao.importar(
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
      expect(aulas.map((a) => (a.turma.turno, a.dia, a.turma.semestre, '${a.inicio}', a.andar)), [
        (Turno.noite, DiaDaSemana.terca, 3, '07:40', Andar.terreo),
        (Turno.manha, DiaDaSemana.sabado, 1, '19:00', Andar.terceiro),
        (Turno.noite, DiaDaSemana.terca, 3, '19:00', Andar.primeiro),
      ]);
    });

    test('as colunas podem vir em qualquer ordem, com o cabeçalho sem acento', () {
      final previa = importacao.importar(
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

    test('linhas totalmente vazias são ignoradas', () {
      final previa = importacao.importar(
        planilha([linha(), List.filled(10, ''), List.filled(10, ' ')]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
      expect(previa.quantidadeDeAulas, 1);
    });

    test('a prévia lista as turmas e as salas encontradas, sem repetição e em ordem', () {
      final previa = importacao.importar(
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

    test('salas escritas de jeitos diferentes viram salas diferentes, e a prévia mostra as duas', () {
      final previa = importacao.importar(planilha([linha(sala: 'Lab 1'), linha(sala: 'lab 1')]), semestreLetivo);

      expect(previa.erros, isEmpty);
      expect(previa.salas.map((s) => s.sala), ['Lab 1', 'lab 1']);
    });

    test('importar não altera a grade publicada; só publicar altera', () async {
      final atual = Grade(semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2), aulas: const []);
      repositorio = RepositorioGradeEmMemoria(atual);
      importacao = ImportacaoDeGrade(repositorio);

      importacao.importar(planilha([linha()]), semestreLetivo);

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
              andar: Andar.primeiro,
            ),
          ],
        ),
      );
      importacao = ImportacaoDeGrade(repositorio);

      await importacao.publicar(importacao.importar(planilha([linha()]), semestreLetivo));

      final grade = (await repositorio.gradeAtual())!;
      expect(grade.semestreLetivo.rotulo, '2027/1');
      expect(grade.aulas.map((a) => a.disciplina), ['Banco de Dados']);
    });
  });

  group('planilha com erro', () {
    test('campo vazio gera erro com o número da linha e o nome da coluna', () {
      final previa = importacao.importar(
        planilha([linha(), linha(sala: ''), linha(dia: 'Terça', professor: '  ')]),
        semestreLetivo,
      );

      expect(erros(previa), ['3 Sala', '4 Professor']);
    });

    test('coluna repetida no cabeçalho gera erro na linha 1', () {
      final previa = importacao.importar(
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

    test('coluna que falta no cabeçalho gera erro na linha 1', () {
      final previa = importacao.importar(
        planilha([linha().sublist(0, 9)], cabecalho: cabecalho.sublist(0, 9)),
        semestreLetivo,
      );

      expect(erros(previa), ['1 Andar']);
    });

    test('horário em formato inválido gera erro na linha', () {
      final previa = importacao.importar(
        planilha([linha(inicio: '19h'), linha(fim: '25:00'), linha(inicio: '19:60')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Início', '3 Fim', '4 Início']);
    });

    test('fim antes do início, ou igual a ele, gera erro na linha', () {
      final previa = importacao.importar(
        planilha([linha(inicio: '20:40', fim: '19:00'), linha(inicio: '19:00', fim: '19:00')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Fim', '3 Fim']);
    });

    test('dia fora de segunda a sábado, incluindo domingo, gera erro na linha', () {
      final previa = importacao.importar(planilha([linha(dia: 'Domingo'), linha(dia: 'Segundaa')]), semestreLetivo);

      expect(erros(previa), ['2 Dia', '3 Dia']);
    });

    test('turno, semestre ou andar fora dos valores possíveis geram erro na linha', () {
      final previa = importacao.importar(
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

    test('duas aulas na mesma sala, no mesmo dia e com horários sobrepostos geram erro nas duas linhas', () {
      final previa = importacao.importar(
        planilha([
          linha(inicio: '19:00', fim: '20:40'),
          linha(semestre: '1', dia: 'Terça'),
          linha(semestre: '5', inicio: '20:00', fim: '22:30'),
        ]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Sala', '4 Sala']);
    });

    test('o conflito de sala aparece mesmo quando a linha tem outro erro', () {
      final previa = importacao.importar(planilha([linha(), linha(semestre: '5', professor: '')]), semestreLetivo);

      expect(erros(previa), ['2 Sala', '3 Professor', '3 Sala']);
    });

    test('com erro, a prévia ainda lista as turmas e as salas das linhas legíveis', () {
      final previa = importacao.importar(
        planilha([linha(professor: ''), linha(curso: 'Gestão', turno: 'Manhã', sala: 'A10', inicio: '25:00')]),
        semestreLetivo,
      );

      expect(previa.turmas.map((t) => t.curso), ['ADS', 'Gestão']);
      expect(previa.salas.map((s) => s.sala), ['A10', 'Lab 1']);
    });

    test('aulas na mesma sala que só se encostam não geram erro', () {
      final previa = importacao.importar(
        planilha([linha(inicio: '19:00', fim: '20:40'), linha(semestre: '5', inicio: '20:40', fim: '22:30')]),
        semestreLetivo,
      );

      expect(previa.erros, isEmpty);
    });

    test('a mesma sala com andares diferentes gera erro nessas linhas', () {
      final previa = importacao.importar(
        planilha([linha(dia: 'Segunda'), linha(dia: 'Terça'), linha(dia: 'Quarta', andar: 'Térreo')]),
        semestreLetivo,
      );

      expect(erros(previa), ['2 Andar', '3 Andar', '4 Andar']);
    });

    test('com qualquer erro, a prévia não pode ser publicada e a grade continua a mesma', () async {
      final previa = importacao.importar(planilha([linha(), linha(sala: '')]), semestreLetivo);

      expect(previa.podePublicar, isFalse);
      await expectLater(importacao.publicar(previa), throwsStateError);
      expect(await repositorio.gradeAtual(), isNull);
    });
  });
}
