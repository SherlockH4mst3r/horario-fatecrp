/// O período do dia em que a turma tem aula.
enum Turno {
  manha('Manhã'),
  tarde('Tarde'),
  noite('Noite');

  const Turno(this.rotulo);

  final String rotulo;
}

/// Dias em que a FATEC pode ter aula: de segunda a sábado.
enum DiaDaSemana {
  segunda('Segunda'),
  terca('Terça'),
  quarta('Quarta'),
  quinta('Quinta'),
  sexta('Sexta'),
  sabado('Sábado');

  const DiaDaSemana(this.rotulo);

  final String rotulo;
}

/// O andar do prédio onde fica a sala. O prédio da FATEC RP tem térreo e mais três andares.
enum Andar {
  terreo('Térreo'),
  primeiro('1º andar'),
  segundo('2º andar'),
  terceiro('3º andar');

  const Andar(this.rotulo);

  final String rotulo;
}

/// O período acadêmico da faculdade, como 2026/2.
class SemestreLetivo {
  const SemestreLetivo({required this.ano, required this.periodo});

  final int ano;
  final int periodo;

  String get rotulo => '$ano/$periodo';
}

/// O grupo de alunos de um curso, num turno e num semestre.
class Turma {
  const Turma({required this.curso, required this.turno, required this.semestre});

  final String curso;
  final Turno turno;
  final int semestre;

  @override
  bool operator ==(Object other) =>
      other is Turma && other.curso == curso && other.turno == turno && other.semestre == semestre;

  @override
  int get hashCode => Object.hash(curso, turno, semestre);
}

/// Hora do dia em que uma aula começa ou termina.
class Horario implements Comparable<Horario> {
  const Horario(this.hora, this.minuto);

  /// Lê o formato `HH:MM`.
  factory Horario.parse(String texto) {
    final [hora, minuto] = texto.split(':').map(int.parse).toList();
    return Horario(hora, minuto);
  }

  final int hora;
  final int minuto;

  int get _minutosDoDia => hora * 60 + minuto;

  @override
  int compareTo(Horario other) => _minutosDoDia.compareTo(other._minutosDoDia);

  @override
  String toString() => '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
}

/// Um encontro semanal fixo de uma turma.
class Aula {
  const Aula({
    required this.turma,
    required this.dia,
    required this.inicio,
    required this.fim,
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.andar,
  });

  final Turma turma;
  final DiaDaSemana dia;
  final Horario inicio;
  final Horario fim;
  final String disciplina;
  final String professor;
  final String sala;
  final Andar andar;
}

/// O conjunto de aulas de um semestre letivo.
class Grade {
  const Grade({required this.semestreLetivo, required this.aulas});

  final SemestreLetivo semestreLetivo;
  final List<Aula> aulas;
}
