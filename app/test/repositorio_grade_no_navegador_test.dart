import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/repositorio_grade_no_navegador.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final grade = Grade(
    semestreLetivo: const SemestreLetivo(ano: 2027, periodo: 1),
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
    ],
  );

  test('sem nada guardado, não há grade publicada', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await RepositorioGradeNoNavegador().gradeAtual(), isNull);
  });

  test('a grade substituída volta igual na próxima leitura', () async {
    SharedPreferences.setMockInitialValues({});

    await RepositorioGradeNoNavegador().substituir(grade);
    final lida = (await RepositorioGradeNoNavegador().gradeAtual())!;

    expect(lida.semestreLetivo.rotulo, '2027/1');
    final aula = lida.aulas.single;
    expect(
      [
        aula.turma,
        aula.dia,
        '${aula.inicio}',
        '${aula.fim}',
        aula.disciplina,
        aula.professor,
        aula.sala,
        aula.andares.map((a) => a.name).join('/'),
      ],
      [
        grade.aulas.single.turma,
        DiaDaSemana.quarta,
        '19:00',
        '22:30',
        'Banco de Dados',
        'Rita Alves',
        'S4/L3',
        'primeiro/terceiro',
      ],
    );
  });

  test('grade guardada ilegível é uma falha, não uma grade vazia', () async {
    SharedPreferences.setMockInitialValues({'grade': '{"semestreLetivo": "2027/1"'});

    await expectLater(RepositorioGradeNoNavegador().gradeAtual(), throwsFormatException);
  });

  test('grade guardada no formato antigo, com um andar só, ainda é lida', () async {
    SharedPreferences.setMockInitialValues({
      'grade':
          '{"semestreLetivo": {"ano": 2026, "periodo": 2}, "aulas": [{"curso": "ADS", "turno": "noite", '
          '"semestre": 3, "dia": "quarta", "inicio": "19:00", "fim": "22:30", "disciplina": "BD", '
          '"professor": "Rita", "sala": "Lab 1", "andar": "segundo"}]}',
    });

    final aula = (await RepositorioGradeNoNavegador().gradeAtual())!.aulas.single;

    expect(aula.andares, [Andar.segundo]);
  });
}
