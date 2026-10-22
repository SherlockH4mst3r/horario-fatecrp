import 'package:grade/grade.dart';
import 'package:test/test.dart';

void main() {
  final grade = Grade(
    semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
    aulas: [
      Aula(
        turma: const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3),
        dia: DiaDaSemana.quarta,
        inicio: Horario.parse('19:00'),
        fim: Horario.parse('22:30'),
        disciplina: 'Banco de Dados',
        professor: 'Rita Alves',
        sala: 'S4/L3',
        andares: const [Andar.primeiro, Andar.terceiro],
      ),
      Aula(
        turma: const Turma(curso: 'GNI', turno: Turno.noite, semestre: 6),
        dia: DiaDaSemana.sabado,
        inicio: Horario.parse('07:40'),
        fim: Horario.parse('11:10'),
        disciplina: 'G MARCAS',
        professor: 'ADRIANO',
        sala: 'A definir – GNI Noite 6º',
        andares: const [],
      ),
    ],
  );

  test('a grade volta igual depois de virar JSON', () {
    final lida = gradeDoJson(gradeComoJson(grade));

    expect(lida.semestreLetivo, grade.semestreLetivo);
    expect(lida.aulas, grade.aulas);
  });

  test('o JSON sai com uma chave por linha, para o histórico do GitHub mostrar só o que mudou', () {
    final linhas = gradeComoJson(grade).split('\n');

    expect(linhas, contains('      "sala": "S4/L3",'));
    expect(gradeComoJson(grade).endsWith('\n'), isTrue);
  });

  test('aceita o formato antigo, com um andar só', () {
    const antigo =
        '{"semestreLetivo": {"ano": 2026, "periodo": 2}, "aulas": [{"curso": "ADS", "turno": "noite", '
        '"semestre": 3, "dia": "quarta", "inicio": "19:00", "fim": "22:30", "disciplina": "BD", '
        '"professor": "Rita", "sala": "Lab 1", "andar": "segundo"}]}';

    expect(gradeDoJson(antigo).aulas.single.andares, [Andar.segundo]);
  });

  test('JSON fora do formato é FormatException', () {
    for (final ruim in ['{"semestreLetivo": "2026/2"', '{"aulas": []}', '[]']) {
      expect(() => gradeDoJson(ruim), throwsFormatException, reason: ruim);
    }
  });
}
