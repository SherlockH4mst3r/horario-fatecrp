import 'package:grade/grade.dart';
import 'package:test/test.dart';

const ads3 = Turma(curso: 'ADS', turno: Turno.noite, semestre: 3);

Aula aula({
  Turma turma = ads3,
  DiaDaSemana dia = DiaDaSemana.segunda,
  String inicio = '19:00',
  String fim = '20:40',
  String disciplina = 'Banco de Dados',
  String professor = 'Rita Alves',
  String sala = 'S14',
  List<Andar> andares = const [Andar.segundo],
}) => Aula(
  turma: turma,
  dia: dia,
  inicio: Horario.parse(inicio),
  fim: Horario.parse(fim),
  disciplina: disciplina,
  professor: professor,
  sala: sala,
  andares: andares,
);

/// A aula como o admin a digita no formulário, com valores válidos por padrão.
AulaDigitada digitada({
  String curso = 'ADS',
  String turno = 'Noite',
  String semestre = '3',
  String dia = 'Terça',
  String inicio = '19:00',
  String fim = '20:40',
  String disciplina = 'Redes',
  String professor = 'Marco A',
  String sala = 'LR',
  String andar = '1º andar',
}) => AulaDigitada(
  curso: curso,
  turno: turno,
  semestre: semestre,
  dia: dia,
  inicio: inicio,
  fim: fim,
  disciplina: disciplina,
  professor: professor,
  sala: sala,
  andar: andar,
);

void main() {
  late RepositorioGradeEmMemoria repositorio;
  late EdicaoDeAulas edicao;
  final bancoDeDados = aula();

  setUp(() {
    repositorio = RepositorioGradeEmMemoria(
      Grade(semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2), aulas: [bancoDeDados]),
    );
    edicao = EdicaoDeAulas(repositorio);
  });

  Future<List<Aula>> aulasPublicadas() async => (await repositorio.gradeAtual())!.aulas;

  Map<String, String> errosDe(ResultadoDaEdicao resultado) => switch (resultado) {
    AulaRecusada(:final erros) => erros,
    AulaSalva() => fail('a aula devia ter sido recusada'),
  };

  group('criar', () {
    test('aula válida entra na grade publicada, junto das outras', () async {
      final resultado = await edicao.salvar(digitada());

      expect(resultado, isA<AulaSalva>());
      expect((await aulasPublicadas()).map((a) => a.disciplina), ['Banco de Dados', 'Redes']);
    });

    test('a grade continua no mesmo semestre letivo', () async {
      await edicao.salvar(digitada());

      expect((await repositorio.gradeAtual())!.semestreLetivo.rotulo, '2026/2');
    });

    test('campo vazio é recusado, com a mensagem no campo', () async {
      final erros = errosDe(await edicao.salvar(digitada(professor: ' ')));

      expect(erros, {'Professor': 'campo vazio'});
      expect(await aulasPublicadas(), [bancoDeDados]);
    });

    test('horário, dia, turno, semestre e andar inválidos são recusados campo a campo', () async {
      final erros = errosDe(
        await edicao.salvar(
          digitada(inicio: '19h', dia: 'Domingo', turno: 'Madrugada', semestre: '9', andar: '5º andar'),
        ),
      );

      expect(erros.keys, ['Turno', 'Semestre', 'Dia', 'Início', 'Andar']);
    });

    test('sala ocupada no mesmo dia e horário é recusada', () async {
      final erros = errosDe(
        await edicao.salvar(
          digitada(semestre: '5', dia: 'Segunda', inicio: '20:00', fim: '21:40', sala: 'S14', andar: '2º andar'),
        ),
      );

      expect(erros, {'Sala': 'a sala S14 já tem aula nesse horário: Banco de Dados, ADS – Noite – 3º, 19:00–20:40'});
    });

    test('sala que já está na grade em outro andar é recusada', () async {
      final erros = errosDe(await edicao.salvar(digitada(sala: 'S14', andar: '3º andar')));

      expect(erros.keys, ['Andar']);
    });

    test('sem grade publicada, não há onde criar a aula', () async {
      edicao = EdicaoDeAulas(RepositorioGradeEmMemoria());

      final erros = errosDe(await edicao.salvar(digitada()));

      expect(erros.values.single, contains('importe uma grade'));
    });
  });

  group('conflitos de turma e de professor', () {
    test('estender a aula até o horário da seguinte da mesma turma é recusado', () async {
      await edicao.salvar(digitada(semestre: '3', dia: 'Segunda', inicio: '20:50', fim: '22:30', sala: 'LR'));

      final erros = errosDe(
        await edicao.salvar(
          digitada(dia: 'Segunda', disciplina: 'Banco de Dados', fim: '21:40', sala: 'S14', andar: '2º andar'),
          original: bancoDeDados,
        ),
      );

      expect(erros, {'Início': 'a turma ADS – Noite – 3º já tem aula nesse horário: Redes, 20:50–22:30'});
      expect(await aulasPublicadas(), contains(bancoDeDados));
    });

    test('o mesmo professor em dois lugares salva a aula, com um aviso', () async {
      final resultado = await edicao.salvar(digitada(semestre: '5', dia: 'Segunda', professor: 'Rita Alves'));

      expect(resultado, isA<AulaSalva>());
      expect((resultado as AulaSalva).avisos, [
        'o professor Rita Alves já tem aula nesse horário: Banco de Dados, ADS – Noite – 3º, 19:00–20:40',
      ]);
    });
  });

  group('editar', () {
    test('troca a aula original pela editada', () async {
      final resultado = await edicao.salvar(
        digitada(dia: 'Segunda', disciplina: 'Banco de Dados', sala: 'S15', andar: '2º andar'),
        original: bancoDeDados,
      );

      expect(resultado, isA<AulaSalva>());
      expect((await aulasPublicadas()).map((a) => '${a.disciplina} ${a.sala}'), ['Banco de Dados S15']);
    });

    test('a aula não conflita com ela mesma', () async {
      final resultado = await edicao.salvar(
        digitada(dia: 'Segunda', disciplina: 'Banco de Dados', professor: 'Ana Souza', sala: 'S14', andar: '2º andar'),
        original: bancoDeDados,
      );

      expect(resultado, isA<AulaSalva>());
      expect((await aulasPublicadas()).single.professor, 'Ana Souza');
    });

    test('mudar a sala para uma ocupada naquele horário é recusado, e a original fica', () async {
      await edicao.salvar(digitada(semestre: '4', dia: 'Segunda', sala: 'LR', andar: '1º andar'));
      final erros = errosDe(
        await edicao.salvar(
          digitada(dia: 'Segunda', disciplina: 'Banco de Dados', sala: 'LR', andar: '1º andar'),
          original: bancoDeDados,
        ),
      );

      expect(erros.keys, ['Sala']);
      expect(await aulasPublicadas(), contains(bancoDeDados));
    });

    test('a forma digitada de uma aula publicada volta a ser a mesma aula', () async {
      final resultado = await edicao.salvar(AulaDigitada.de(bancoDeDados), original: bancoDeDados);

      expect(resultado, isA<AulaSalva>());
      expect(await aulasPublicadas(), [bancoDeDados]);
    });
  });

  group('excluir', () {
    test('tira a aula da grade publicada', () async {
      await edicao.salvar(digitada());

      await edicao.excluir(bancoDeDados);

      expect((await aulasPublicadas()).map((a) => a.disciplina), ['Redes']);
    });

    test('com duas aulas iguais, tira uma só', () async {
      repositorio = RepositorioGradeEmMemoria(
        Grade(semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2), aulas: [bancoDeDados, aula()]),
      );
      edicao = EdicaoDeAulas(repositorio);

      await edicao.excluir(bancoDeDados);

      expect(await aulasPublicadas(), hasLength(1));
    });
  });

  group('consulta do painel', () {
    test('lista as turmas da grade publicada, em ordem', () async {
      await edicao.salvar(digitada(curso: 'GRH', turno: 'Manhã', semestre: '1'));
      await edicao.salvar(digitada(semestre: '1', dia: 'Sexta'));

      expect((await edicao.turmas()).map((t) => t.rotulo), [
        'ADS – Noite – 1º',
        'ADS – Noite – 3º',
        'GRH – Manhã – 1º',
      ]);
    });

    test('lista as aulas de uma turma por dia e início', () async {
      await edicao.salvar(digitada(semestre: '3', dia: 'Segunda', inicio: '20:50', fim: '22:30'));
      await edicao.salvar(digitada(semestre: '3', dia: 'Sábado', inicio: '07:40', fim: '09:20', sala: 'LA'));

      expect((await edicao.aulasDaTurma(ads3)).map((a) => '${a.dia.rotulo} ${a.inicio} ${a.disciplina}'), [
        'Segunda 19:00 Banco de Dados',
        'Segunda 20:50 Redes',
        'Sábado 07:40 Redes',
      ]);
    });

    test('sem grade publicada, não há turmas', () async {
      expect(await EdicaoDeAulas(RepositorioGradeEmMemoria()).turmas(), isEmpty);
    });
  });
}
