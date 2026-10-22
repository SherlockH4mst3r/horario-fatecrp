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

  /// O dia letivo de uma data; `null` no domingo, que não tem aula.
  static DiaDaSemana? letivoDe(DateTime data) =>
      data.weekday == DateTime.sunday ? null : DiaDaSemana.values[data.weekday - 1];

  final String rotulo;

  /// Os dias seguintes a este, voltando à segunda depois do sábado.
  List<DiaDaSemana> get seguintes => [...values.skip(index + 1), ...values.take(index)];
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

  /// Lê o semestre letivo como o admin digita, `ano/período` (ex.: 2027/1); devolve `null` se não for um.
  static SemestreLetivo? tentarLer(String texto) {
    final partes = RegExp(r'^(\d{4})\s*/\s*([12])$').firstMatch(texto.trim());
    if (partes == null) return null;
    return SemestreLetivo(ano: int.parse(partes[1]!), periodo: int.parse(partes[2]!));
  }

  final int ano;
  final int periodo;

  String get rotulo => '$ano/$periodo';

  @override
  bool operator ==(Object other) => other is SemestreLetivo && other.ano == ano && other.periodo == periodo;

  @override
  int get hashCode => Object.hash(ano, periodo);
}

/// O grupo de alunos de um curso, num turno e num semestre.
class Turma implements Comparable<Turma> {
  const Turma({required this.curso, required this.turno, required this.semestre});

  final String curso;
  final Turno turno;
  final int semestre;

  @override
  bool operator ==(Object other) =>
      other is Turma && other.curso == curso && other.turno == turno && other.semestre == semestre;

  @override
  int get hashCode => Object.hash(curso, turno, semestre);

  /// Como "ADS – Noite – 3º".
  String get rotulo => '$curso – ${turno.rotulo} – $semestreº';

  /// Por curso, turno e semestre.
  @override
  int compareTo(Turma other) {
    final porCurso = curso.compareTo(other.curso);
    if (porCurso != 0) return porCurso;
    final porTurno = turno.index.compareTo(other.turno.index);
    return porTurno != 0 ? porTurno : semestre.compareTo(other.semestre);
  }
}

/// Todo curso vai do 1º ao 6º semestre.
const semestresDoCurso = [1, 2, 3, 4, 5, 6];

/// Hora do dia em que uma aula começa ou termina.
class Horario implements Comparable<Horario> {
  const Horario(this.hora, this.minuto);

  /// Lê o formato `HH:MM`.
  factory Horario.parse(String texto) =>
      tentarLer(texto) ?? (throw FormatException('Horário fora do formato HH:MM', texto));

  /// Lê `HH:MM` ou `H:MM`, aceitando segundos zerados (`19:00:00`, como o Excel escreve); devolve `null` se o
  /// texto não for uma hora válida do dia.
  static Horario? tentarLer(String texto) {
    final partes = RegExp(r'^(\d{1,2}):(\d{2})(:00)?$').firstMatch(texto.trim());
    if (partes == null) return null;
    final [hora, minuto] = [int.parse(partes[1]!), int.parse(partes[2]!)];
    if (hora > 23 || minuto > 59) return null;
    return Horario(hora, minuto);
  }

  final int hora;
  final int minuto;

  int get _minutosDoDia => hora * 60 + minuto;

  int minutosDesde(Horario outro) => _minutosDoDia - outro._minutosDoDia;

  @override
  int compareTo(Horario other) => _minutosDoDia.compareTo(other._minutosDoDia);

  @override
  bool operator ==(Object other) => other is Horario && other._minutosDoDia == _minutosDoDia;

  @override
  int get hashCode => _minutosDoDia.hashCode;

  @override
  String toString() => '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
}

/// Um encontro semanal fixo de uma turma.
class Aula implements Comparable<Aula> {
  const Aula({
    required this.turma,
    required this.dia,
    required this.inicio,
    required this.fim,
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.andares,
  });

  final Turma turma;
  final DiaDaSemana dia;
  final Horario inicio;
  final Horario fim;
  final String disciplina;
  final String professor;

  /// Como está na planilha. Uma aula pode alternar entre duas salas, conforme o conteúdo do dia ("S4/L3").
  final String sala;

  /// O andar de cada sala, na ordem em que elas aparecem em [sala]; vazio quando a sala ainda está a definir.
  final List<Andar> andares;

  /// Como o aluno lê: "1º andar/3º andar", um andar só quando as salas ficam no mesmo, e vazio na sala a definir.
  String get andaresPorExtenso => {for (final andar in andares) andar.rotulo}.join('/');

  @override
  bool operator ==(Object other) =>
      other is Aula &&
      other.turma == turma &&
      other.dia == dia &&
      other.inicio == inicio &&
      other.fim == fim &&
      other.disciplina == disciplina &&
      other.professor == professor &&
      other.sala == sala &&
      other.andares.length == andares.length &&
      [for (final (i, andar) in andares.indexed) other.andares[i] == andar].every((igual) => igual);

  @override
  int get hashCode => Object.hash(turma, dia, inicio, fim, disciplina, professor, sala, Object.hashAll(andares));

  /// Na ordem da grade: por turma, dia e início.
  @override
  int compareTo(Aula other) {
    final porTurma = turma.compareTo(other.turma);
    if (porTurma != 0) return porTurma;
    final porDia = dia.index.compareTo(other.dia.index);
    return porDia != 0 ? porDia : inicio.compareTo(other.inicio);
  }
}

/// O conjunto de aulas de um semestre letivo.
class Grade {
  const Grade({required this.semestreLetivo, required this.aulas});

  final SemestreLetivo semestreLetivo;
  final List<Aula> aulas;
}
