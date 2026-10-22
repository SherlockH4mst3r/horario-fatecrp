import 'package:grade/grade.dart';
import 'package:test/test.dart';

Aula aula({String sala = 'S14', String disciplina = 'Banco de Dados', int semestre = 3}) => Aula(
  turma: Turma(curso: 'ADS', turno: Turno.noite, semestre: semestre),
  dia: DiaDaSemana.segunda,
  inicio: Horario.parse('19:00'),
  fim: Horario.parse('20:40'),
  disciplina: disciplina,
  professor: 'Rita Alves',
  sala: sala,
  andares: const [Andar.segundo],
);

void main() {
  const semestre = SemestreLetivo(ano: 2026, periodo: 2);

  test('grade válida passa na conferência, com os avisos que tiver', () async {
    final previa = await conferirGrade(
      Grade(
        semestreLetivo: semestre,
        aulas: [
          aula(),
          aula(sala: 'S15', disciplina: 'Redes', semestre: 5),
        ],
      ),
    );

    expect(previa.erros, isEmpty);
    expect(previa.avisos, hasLength(2), reason: 'o mesmo professor em duas salas ao mesmo tempo');
  });

  test('grade com conflito de sala não passa, com o erro apontado', () async {
    final previa = await conferirGrade(
      Grade(
        semestreLetivo: semestre,
        aulas: [
          aula(),
          aula(disciplina: 'Redes', semestre: 5),
        ],
      ),
    );

    expect([for (final erro in previa.erros) erro.coluna], ['Sala', 'Sala']);
  });
}
