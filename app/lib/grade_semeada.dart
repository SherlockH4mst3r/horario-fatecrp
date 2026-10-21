import 'package:grade/grade.dart';

/// Grade de exemplo usada enquanto o site não está ligado ao Supabase.
/// Os dados são fictícios.
final gradeSemeada = Grade(
  semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
  aulas: [
    ..._turma(const Turma(curso: 'ADS', turno: Turno.noite, semestre: 1), [
      (DiaDaSemana.segunda, '19:00', '20:40', 'Algoritmos', 'Ana Souza', 'B12'),
      (DiaDaSemana.segunda, '20:50', '22:30', 'Matemática Discreta', 'Carlos Lima', 'B12'),
      (DiaDaSemana.terca, '19:00', '22:30', 'Lógica de Programação', 'Ana Souza', 'Lab 3'),
      (DiaDaSemana.quinta, '19:00', '20:40', 'Inglês I', 'Marta Reis', 'A04'),
    ]),
    ..._turma(const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3), [
      (DiaDaSemana.segunda, '19:00', '20:40', 'Engenharia de Software', 'Paulo Nunes', 'B14'),
      (DiaDaSemana.quarta, '19:00', '22:30', 'Banco de Dados', 'Rita Alves', 'Lab 1'),
      (DiaDaSemana.sabado, '08:00', '11:30', 'Projeto Integrador', 'Paulo Nunes', 'Lab 2'),
    ]),
    ..._turma(const Turma(curso: 'Gestão Empresarial', turno: Turno.manha, semestre: 2), [
      (DiaDaSemana.terca, '07:40', '09:20', 'Contabilidade', 'José Prado', 'A10'),
      (DiaDaSemana.sexta, '09:30', '11:10', 'Marketing', 'Lúcia Torres', 'A11'),
    ]),
  ],
);

Iterable<Aula> _turma(
  Turma turma,
  List<(DiaDaSemana, String, String, String, String, String)> aulas,
) =>
    aulas.map((a) {
      final (dia, inicio, fim, disciplina, professor, sala) = a;
      return Aula(
        turma: turma,
        dia: dia,
        inicio: Horario.parse(inicio),
        fim: Horario.parse(fim),
        disciplina: disciplina,
        professor: professor,
        sala: sala,
      );
    });
