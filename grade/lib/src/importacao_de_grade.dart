import 'diferencas.dart';
import 'grade.dart';
import 'repositorio_grade.dart';

/// O conteúdo de uma planilha como texto: o cabeçalho (linha 1) e as linhas de dados, a partir da linha 2.
class Planilha {
  const Planilha({required this.cabecalho, required this.linhas});

  final List<String> cabecalho;
  final List<List<String>> linhas;
}

/// Um problema da planilha, apontado como o admin o encontra no Excel: linha e coluna.
class ErroNaPlanilha {
  const ErroNaPlanilha({required this.linha, required this.coluna, required this.mensagem, this.outraLinha});

  final int linha;
  final String coluna;
  final String mensagem;

  /// Num conflito, a linha da outra aula envolvida.
  final int? outraLinha;
}

typedef SalaEncontrada = ({String sala, Andar andar});

/// O que a importação vai publicar, para o admin conferir antes.
class Previa {
  Previa._({
    required this.semestreLetivo,
    required this.erros,
    required this.avisos,
    required this.turmas,
    required this.salas,
    required this.diferencas,
    required List<Aula> aulas,
  }) : _aulas = aulas;

  final SemestreLetivo semestreLetivo;

  /// Em ordem de linha e, na mesma linha, de coluna.
  final List<ErroNaPlanilha> erros;

  /// Como os erros, mas não impedem a publicação: o mesmo professor em duas aulas ao mesmo tempo, que pode ser
  /// de propósito (a grade oficial da Fatec tem casos assim).
  final List<ErroNaPlanilha> avisos;

  /// As turmas das linhas legíveis, mesmo as que têm erro em outra coluna; sem repetição e em ordem.
  final List<Turma> turmas;

  /// Cada sala das linhas legíveis (uma sala dupla, como "S4/L3", conta como duas), sem repetição e por nome.
  /// Uma sala com dois andares aparece duas vezes, para o admin ver o problema.
  final List<SalaEncontrada> salas;

  /// O que muda em relação à grade publicada; `null` enquanto a planilha tem erro, porque as linhas com erro
  /// pareceriam aulas removidas.
  final Diferencas? diferencas;

  /// Só as linhas sem erro; com qualquer erro na planilha, nada é publicado.
  final List<Aula> _aulas;

  bool get podePublicar => erros.isEmpty;

  int get quantidadeDeAulas => _aulas.length;
}

/// Caso de uso do admin: trocar a grade do semestre letivo pela de uma planilha, conferida antes na prévia.
class ImportacaoDeGrade {
  ImportacaoDeGrade(this._repositorio);

  final RepositorioGrade _repositorio;

  /// Lê e valida a planilha e a compara com a grade publicada, sem alterá-la.
  Future<Previa> importar(Planilha planilha, SemestreLetivo semestreLetivo) async {
    final (:colunas, errosDoCabecalho: erros) = _lerCabecalho(planilha.cabecalho);
    final linhas = erros.isEmpty ? _lerLinhas(planilha.linhas, colunas) : const <_LinhaLida>[];
    erros.addAll([for (final linha in linhas) ...linha.erros]);
    final aoMesmoTempo = _aoMesmoTempo(linhas).toList();
    erros.addAll(_conflitosDeSala(aoMesmoTempo));
    erros.addAll(_conflitosDeTurma(aoMesmoTempo));
    erros.addAll(_salasEmAndaresDiferentes(linhas));

    final aulas = [for (final linha in linhas) ?linha.aula];
    final diferencas = erros.isEmpty
        ? Diferencas.entre(
            publicada: await _repositorio.gradeAtual(),
            importada: Grade(semestreLetivo: semestreLetivo, aulas: aulas),
          )
        : null;
    return Previa._(
      semestreLetivo: semestreLetivo,
      erros: [for (final erro in _emOrdem(erros)) erro.paraOAdmin],
      avisos: [for (final aviso in _emOrdem(_professorEmDoisLugares(aoMesmoTempo).toList())) aviso.paraOAdmin],
      diferencas: diferencas,
      turmas: {for (final linha in linhas) ?linha.turma}.toList()..sort(),
      salas: {for (final linha in linhas) ...linha.salasEncontradas}.toList()..sort(_porSalaEAndar),
      aulas: aulas,
    );
  }

  /// Substitui a grade inteira pela da prévia. Recusa a prévia com erro.
  Future<void> publicar(Previa previa) async {
    if (!previa.podePublicar) throw StateError('A prévia tem erros e não pode ser publicada.');
    await _repositorio.substituir(Grade(semestreLetivo: previa.semestreLetivo, aulas: previa._aulas));
  }

  ({Map<_Coluna, int> colunas, List<_Erro> errosDoCabecalho}) _lerCabecalho(List<String> cabecalho) {
    final porNome = {for (final coluna in _Coluna.values) _normalizar(coluna.nome): coluna};
    final colunas = <_Coluna, int>{};
    final erros = <_Erro>[];
    for (final (indice, titulo) in cabecalho.indexed) {
      final coluna = porNome[_normalizar(titulo)];
      if (coluna == null) continue; // Coluna de anotação do admin: não entra na grade.
      if (colunas.containsKey(coluna)) {
        erros.add(_Erro(1, coluna, 'coluna repetida no cabeçalho'));
      } else {
        colunas[coluna] = indice;
      }
    }
    for (final coluna in _Coluna.values) {
      if (!colunas.containsKey(coluna)) erros.add(_Erro(1, coluna, 'coluna não encontrada no cabeçalho'));
    }
    return (colunas: colunas, errosDoCabecalho: erros);
  }

  List<_LinhaLida> _lerLinhas(List<List<String>> linhas, Map<_Coluna, int> colunas) => [
    for (final (indice, celulas) in linhas.indexed)
      if (celulas.any((celula) => celula.trim().isNotEmpty))
        _LinhaLida.ler(indice + 2, (coluna) {
          final posicao = colunas[coluna]!;
          return posicao < celulas.length ? celulas[posicao].trim() : '';
        }),
  ];

  /// Os pares de linhas com aula no mesmo dia e horários que se sobrepõem. Encostar (uma acaba quando a outra
  /// começa) não é sobrepor. Vale também para linhas com erro em outra coluna.
  Iterable<(_LinhaLida, _LinhaLida)> _aoMesmoTempo(List<_LinhaLida> linhas) sync* {
    final comHorario = [
      for (final linha in linhas)
        if (linha.dia != null && linha.inicio != null && linha.fim != null) linha,
    ];
    for (final (i, a) in comHorario.indexed) {
      for (final b in comHorario.skip(i + 1)) {
        if (a.dia == b.dia && a.inicio!.compareTo(b.fim!) < 0 && b.inicio!.compareTo(a.fim!) < 0) yield (a, b);
      }
    }
  }

  /// Duas aulas na mesma sala ao mesmo tempo: erro nas duas linhas.
  Iterable<_Erro> _conflitosDeSala(List<(_LinhaLida, _LinhaLida)> aoMesmoTempo) => _nasDuasLinhas(
    aoMesmoTempo,
    coluna: _Coluna.sala,
    seConflitam: (a, b) => a.sala != null && a.sala == b.sala,
    mensagem: (linha, outra) => 'a sala ${linha.sala} já tem aula nesse horário: ${outra.descricao()}',
  );

  /// A mesma turma em duas aulas ao mesmo tempo: o aluno não pode estar nos dois lugares.
  Iterable<_Erro> _conflitosDeTurma(List<(_LinhaLida, _LinhaLida)> aoMesmoTempo) => _nasDuasLinhas(
    aoMesmoTempo,
    coluna: _Coluna.inicio,
    seConflitam: (a, b) => a.turma != null && a.turma == b.turma,
    mensagem: (linha, outra) =>
        'a turma ${linha.turma!.rotulo} já tem aula nesse horário: ${outra.descricao(comTurma: false)}',
  );

  Iterable<_Erro> _professorEmDoisLugares(List<(_LinhaLida, _LinhaLida)> aoMesmoTempo) => _nasDuasLinhas(
    aoMesmoTempo,
    coluna: _Coluna.professor,
    seConflitam: (a, b) => a.professor != null && a.professor == b.professor,
    mensagem: (linha, outra) => 'o professor ${linha.professor} já tem aula nesse horário: ${outra.descricao()}',
  );

  Iterable<_Erro> _nasDuasLinhas(
    List<(_LinhaLida, _LinhaLida)> aoMesmoTempo, {
    required _Coluna coluna,
    required bool Function(_LinhaLida a, _LinhaLida b) seConflitam,
    required String Function(_LinhaLida linha, _LinhaLida outra) mensagem,
  }) sync* {
    for (final (a, b) in aoMesmoTempo) {
      if (!seConflitam(a, b)) continue;
      yield _Erro(a.numero, coluna, mensagem(a, b), outraLinha: b.numero);
      yield _Erro(b.numero, coluna, mensagem(b, a), outraLinha: a.numero);
    }
  }

  /// Olha cada sala sozinha: a L1 de "L1/S2" é a mesma L1 de outra linha.
  Iterable<_Erro> _salasEmAndaresDiferentes(List<_LinhaLida> linhas) sync* {
    final andaresPorSala = <String, Set<Andar>>{};
    for (final (:sala, :andar) in [for (final linha in linhas) ...linha.salasEncontradas]) {
      andaresPorSala.putIfAbsent(sala, () => {}).add(andar);
    }
    for (final linha in linhas) {
      final emDoisAndares = [
        for (final (:sala, andar: _) in linha.salasEncontradas)
          if (andaresPorSala[sala]!.length > 1) sala,
      ];
      if (emDoisAndares.isNotEmpty) {
        yield _Erro(linha.numero, _Coluna.andar, 'a sala ${emDoisAndares.join(' e ')} aparece em andares diferentes');
      }
    }
  }

  /// Por linha e coluna; na mesma célula, na ordem em que os erros foram achados.
  List<_Erro> _emOrdem(List<_Erro> erros) {
    final numerados = erros.indexed.toList()
      ..sort((a, b) {
        final porPosicao = a.$2.compareTo(b.$2);
        return porPosicao != 0 ? porPosicao : a.$1.compareTo(b.$1);
      });
    return [for (final (_, erro) in numerados) erro];
  }

  int _porSalaEAndar(SalaEncontrada a, SalaEncontrada b) {
    final porSala = a.sala.compareTo(b.sala);
    return porSala != 0 ? porSala : a.andar.index.compareTo(b.andar.index);
  }
}

/// As colunas que a planilha precisa ter, como o admin as escreve no cabeçalho.
final colunasDaPlanilha = [for (final coluna in _Coluna.values) coluna.nome];

/// As colunas da planilha, na ordem em que os erros de uma mesma linha aparecem.
enum _Coluna {
  curso('Curso'),
  turno('Turno'),
  semestre('Semestre'),
  dia('Dia'),
  inicio('Início'),
  fim('Fim'),
  disciplina('Disciplina'),
  professor('Professor'),
  sala('Sala'),
  andar('Andar');

  const _Coluna(this.nome);

  final String nome;
}

class _Erro implements Comparable<_Erro> {
  _Erro(this.linha, this.coluna, this.mensagem, {this.outraLinha});

  final int linha;
  final _Coluna coluna;
  final String mensagem;
  final int? outraLinha;

  ErroNaPlanilha get paraOAdmin =>
      ErroNaPlanilha(linha: linha, coluna: coluna.nome, mensagem: mensagem, outraLinha: outraLinha);

  @override
  int compareTo(_Erro other) =>
      linha != other.linha ? linha.compareTo(other.linha) : coluna.index.compareTo(other.coluna.index);
}

/// Uma linha da planilha já lida: cada campo legível e os erros dos que não são.
class _LinhaLida {
  _LinhaLida._(
    this.numero,
    this.erros, {
    required this.curso,
    required this.turno,
    required this.semestre,
    required this.dia,
    required this.inicio,
    required this.fim,
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.andares,
  });

  /// Lê todos os campos de uma vez, juntando os erros da linha em vez de parar no primeiro.
  factory _LinhaLida.ler(int numero, String Function(_Coluna coluna) celula) {
    final erros = <_Erro>[];

    String? texto(_Coluna coluna) {
      final texto = celula(coluna);
      if (texto.isNotEmpty) return texto;
      erros.add(_Erro(numero, coluna, 'campo vazio'));
      return null;
    }

    T? valor<T>(_Coluna coluna, Map<String, T> aceitos, String mensagem) {
      final lido = texto(coluna);
      if (lido == null) return null;
      if (aceitos[_normalizar(lido)] case final valor?) return valor;
      erros.add(_Erro(numero, coluna, mensagem));
      return null;
    }

    Horario? horario(_Coluna coluna) {
      final lido = texto(coluna);
      if (lido == null) return null;
      if (Horario.tentarLer(lido) case final horario?) return horario;
      erros.add(_Erro(numero, coluna, 'horário deve estar no formato HH:MM, como 19:00'));
      return null;
    }

    /// Um andar por sala, na mesma ordem ("1º andar/3º andar" para "S4/L3"), ou um só para todas. Sala a
    /// definir pode vir sem andar.
    List<Andar>? andares(String? sala) {
      final salas = sala?.split('/') ?? const [];
      if (celula(_Coluna.andar).isEmpty && sala != null && _aDefinir(sala)) return const [];
      final lido = texto(_Coluna.andar);
      if (lido == null) return null;
      final partes = [for (final parte in lido.split('/')) _andares[_normalizar(parte)]];
      if (partes.contains(null)) {
        erros.add(_Erro(numero, _Coluna.andar, 'andar deve ser ${_umDe(Andar.values.map((a) => a.rotulo))}'));
        return null;
      }
      if (partes.length == 1 && salas.length > 1) return List.filled(salas.length, partes.single!);
      if (sala != null && partes.length != salas.length) {
        erros.add(_Erro(numero, _Coluna.andar, 'informe um andar por sala, na ordem, como "1º andar/3º andar"'));
        return null;
      }
      return partes.cast<Andar>();
    }

    /// Uma sala, ou duas separadas por barra ("L1/S2"), sem espaços em volta da barra.
    String? salaLida() {
      final lido = texto(_Coluna.sala);
      if (lido == null) return null;
      final salas = [for (final parte in lido.split('/')) parte.trim()];
      if (salas.contains('')) {
        erros.add(_Erro(numero, _Coluna.sala, 'sala dupla com uma das salas vazia, como em "L1/"'));
        return null;
      }
      return salas.join('/');
    }

    final sala = salaLida();
    final inicio = horario(_Coluna.inicio);
    var fim = horario(_Coluna.fim);
    if (inicio != null && fim != null && fim.compareTo(inicio) <= 0) {
      erros.add(_Erro(numero, _Coluna.fim, 'o fim deve ser depois do início'));
      fim = null;
    }
    return _LinhaLida._(
      numero,
      erros,
      curso: texto(_Coluna.curso),
      turno: valor(_Coluna.turno, _turnos, 'turno deve ser ${_umDe(Turno.values.map((t) => t.rotulo))}'),
      semestre: valor(
        _Coluna.semestre,
        _semestres,
        'semestre deve ser de ${semestresDoCurso.first} a ${semestresDoCurso.last}',
      ),
      dia: valor(_Coluna.dia, _dias, 'dia deve ser de segunda a sábado'),
      inicio: inicio,
      fim: fim,
      disciplina: texto(_Coluna.disciplina),
      professor: texto(_Coluna.professor),
      sala: sala,
      andares: andares(sala),
    );
  }

  final int numero;
  final List<_Erro> erros;
  final String? curso;
  final Turno? turno;
  final int? semestre;
  final DiaDaSemana? dia;
  final Horario? inicio;
  final Horario? fim;
  final String? disciplina;
  final String? professor;
  final String? sala;
  final List<Andar>? andares;

  Turma? get turma => switch ((curso, turno, semestre)) {
    (final curso?, final turno?, final semestre?) => Turma(curso: curso, turno: turno, semestre: semestre),
    _ => null,
  };

  List<SalaEncontrada> get salasEncontradas => switch ((sala, andares)) {
    (final sala?, final andares?) when andares.isNotEmpty => [
      for (final (indice, nome) in sala.split('/').indexed) (sala: nome.trim(), andar: andares[indice]),
    ],
    _ => const [],
  };

  /// A aula da linha para uma mensagem de conflito: "Redes, ADS – Noite – 5º, 20:00–21:40".
  String descricao({bool comTurma = true}) => [
    ?disciplina,
    if (comTurma) ?turma?.rotulo,
    if ((inicio, fim) case (final inicio?, final fim?)) '$inicio–$fim',
  ].join(', ');

  /// Onde e quando a linha ocupa uma sala, se ela diz isso sem erro.
  ({String sala, DiaDaSemana dia, Horario inicio, Horario fim})? get ocupacao => switch ((sala, dia, inicio, fim)) {
    (final sala?, final dia?, final inicio?, final fim?) => (sala: sala, dia: dia, inicio: inicio, fim: fim),
    _ => null,
  };

  /// A aula da linha, só quando ela não tem nenhum erro.
  Aula? get aula => erros.isEmpty
      ? Aula(
          turma: turma!,
          dia: dia!,
          inicio: inicio!,
          fim: fim!,
          disciplina: disciplina!,
          professor: professor!,
          sala: sala!,
          andares: andares!,
        )
      : null;
}

/// As escritas aceitas de cada valor, já normalizadas: sem acento, sem "º" e em minúsculas.
final _turnos = {for (final turno in Turno.values) _normalizar(turno.rotulo): turno};
final _semestres = {for (final semestre in semestresDoCurso) '$semestre': semestre};
final _dias = {
  for (final dia in DiaDaSemana.values) ...{_normalizar(dia.rotulo): dia, '${_normalizar(dia.rotulo)} feira': dia},
};

/// "Térreo", "1º andar", "1º" ou só "1".
final _andares = {
  for (final andar in Andar.values) ...{
    _normalizar(andar.rotulo): andar,
    if (andar != Andar.terreo) '${andar.index}': andar,
  },
};

/// Sala ainda sem lugar, como "A definir – ADS Noite 6º".
bool _aDefinir(String sala) => _normalizar(sala).startsWith('a definir');

String _umDe(Iterable<String> opcoes) {
  final [...primeiras, ultima] = opcoes.toList();
  return '${primeiras.join(', ')} ou $ultima';
}

/// Deixa o texto comparável ao que o admin pode ter digitado: sem acento, sem "º", sem hífen, em minúsculas
/// e com espaços simples.
String _normalizar(String texto) {
  const semAcento = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ç': 'c',
  };
  final minusculo = texto.toLowerCase().replaceAll(RegExp('[º°ª]'), '').replaceAll('-', ' ');
  final letras = [for (final letra in minusculo.split('')) semAcento[letra] ?? letra].join();
  return letras.trim().replaceAll(RegExp(r'\s+'), ' ');
}
