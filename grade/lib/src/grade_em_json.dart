import 'dart:convert';

import 'grade.dart';

/// A grade como JSON, o formato em que ela é guardada (no navegador ou no repositório do GitHub).
///
/// Sai com uma chave por linha, para o histórico do GitHub mostrar só o que mudou em cada publicação.
String gradeComoJson(Grade grade) => '${const JsonEncoder.withIndent('  ').convert(_json(grade))}\n';

/// Lança [FormatException] quando o texto não é uma grade.
Grade gradeDoJson(String texto) => _grade(jsonDecode(texto));

Map<String, Object> _json(Grade grade) => {
  'semestreLetivo': {'ano': grade.semestreLetivo.ano, 'periodo': grade.semestreLetivo.periodo},
  'aulas': [
    for (final aula in grade.aulas)
      {
        'curso': aula.turma.curso,
        'turno': aula.turma.turno.name,
        'semestre': aula.turma.semestre,
        'dia': aula.dia.name,
        'inicio': '${aula.inicio}',
        'fim': '${aula.fim}',
        'disciplina': aula.disciplina,
        'professor': aula.professor,
        'sala': aula.sala,
        'andares': [for (final andar in aula.andares) andar.name],
      },
  ],
};

Grade _grade(Object? json) => switch (json) {
  {'semestreLetivo': {'ano': int ano, 'periodo': int periodo}, 'aulas': List<Object?> aulas} => Grade(
    semestreLetivo: SemestreLetivo(ano: ano, periodo: periodo),
    aulas: [for (final aula in aulas) _aula(aula)],
  ),
  _ => throw const FormatException('Grade fora do formato'),
};

Aula _aula(Object? json) => switch (json) {
  {
    'curso': String curso,
    'turno': String turno,
    'semestre': int semestre,
    'dia': String dia,
    'inicio': String inicio,
    'fim': String fim,
    'disciplina': String disciplina,
    'professor': String professor,
    'sala': String sala,
  } =>
    Aula(
      turma: Turma(curso: curso, turno: _porNome(Turno.values, turno), semestre: semestre),
      dia: _porNome(DiaDaSemana.values, dia),
      inicio: Horario.parse(inicio),
      fim: Horario.parse(fim),
      disciplina: disciplina,
      professor: professor,
      sala: sala,
      andares: _andares(json),
    ),
  _ => throw const FormatException('Aula fora do formato'),
};

/// Aceita também o formato antigo, de antes das salas duplas, com um andar só.
List<Andar> _andares(Map<Object?, Object?> aula) => switch (aula) {
  {'andares': List<Object?> nomes} => [for (final nome in nomes) _porNome(Andar.values, nome is String ? nome : '')],
  {'andar': String nome} => [_porNome(Andar.values, nome)],
  _ => throw const FormatException('Aula sem andar'),
};

T _porNome<T extends Enum>(List<T> valores, String nome) =>
    valores.asNameMap()[nome] ?? (throw FormatException('Valor desconhecido', nome));
