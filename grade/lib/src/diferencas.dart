import 'grade.dart';

/// Um campo de uma aula que muda com a importação, com o valor antigo e o novo como o admin os lê.
class MudancaDeCampo {
  const MudancaDeCampo({required this.campo, required this.antes, required this.depois});

  final String campo;
  final String antes;
  final String depois;
}

/// Uma aula que continua na grade, mas com sala, horário, professor ou andar diferentes.
class AulaAlterada {
  const AulaAlterada({required this.antes, required this.depois, required this.mudancas});

  final Aula antes;
  final Aula depois;

  /// Na ordem: início, fim, professor, sala e andar.
  final List<MudancaDeCampo> mudancas;
}

/// O que a importação muda em relação à grade publicada, para o admin conferir o impacto antes de publicar.
class Diferencas {
  const Diferencas._({
    required this.semestreLetivo,
    required this.novas,
    required this.removidas,
    required this.alteradas,
  });

  /// Uma aula é a mesma quando coincidem turma, disciplina e dia. Se a mesma disciplina aparece mais de uma vez
  /// no dia, ficam juntas primeiro as aulas com o mesmo início, e as demais pela ordem de início; as que sobram
  /// são novas ou removidas.
  factory Diferencas.entre({required Grade? publicada, required Grade importada}) {
    final antesPorAula = _porIdentidade(publicada?.aulas ?? const []);
    final importadas = importada.aulas;
    final depoisPorAula = _porIdentidade(importadas);
    final novas = <Aula>[];
    final removidas = <Aula>[];
    final alteradas = <AulaAlterada>[];
    for (final identidade in {...antesPorAula.keys, ...depoisPorAula.keys}) {
      final (antes, depois) = _emParesPeloInicio(
        antesPorAula[identidade] ?? const [],
        depoisPorAula[identidade] ?? const [],
      );
      novas.addAll(depois.skip(antes.length));
      removidas.addAll(antes.skip(depois.length));
      for (var i = 0; i < antes.length && i < depois.length; i++) {
        final mudancas = _mudancas(antes[i], depois[i]);
        if (mudancas.isNotEmpty) alteradas.add(AulaAlterada(antes: antes[i], depois: depois[i], mudancas: mudancas));
      }
    }
    final semestreAntes = publicada?.semestreLetivo;
    return Diferencas._(
      semestreLetivo: semestreAntes != null && semestreAntes != importada.semestreLetivo
          ? (antes: semestreAntes, depois: importada.semestreLetivo)
          : null,
      novas: novas..sort(),
      removidas: removidas..sort(),
      alteradas: alteradas..sort((a, b) => a.antes.compareTo(b.antes)),
    );
  }

  /// A troca de semestre letivo, quando a planilha é de outro semestre que o da grade publicada.
  final ({SemestreLetivo antes, SemestreLetivo depois})? semestreLetivo;

  /// Todas em ordem de turma, dia e início.
  final List<Aula> novas;
  final List<Aula> removidas;
  final List<AulaAlterada> alteradas;

  bool get nenhuma => semestreLetivo == null && novas.isEmpty && removidas.isEmpty && alteradas.isEmpty;
}

typedef _Identidade = (Turma, String, DiaDaSemana);

Map<_Identidade, List<Aula>> _porIdentidade(List<Aula> aulas) {
  final porIdentidade = <_Identidade, List<Aula>>{};
  for (final aula in aulas) {
    porIdentidade.putIfAbsent((aula.turma, aula.disciplina, aula.dia), () => []).add(aula);
  }
  for (final mesmas in porIdentidade.values) {
    mesmas.sort((a, b) => a.inicio.compareTo(b.inicio));
  }
  return porIdentidade;
}

/// Reordena as aulas de uma mesma identidade para que fiquem lado a lado, primeiro, as de mesmo início; as
/// restantes seguem pela ordem de início. Assim, tirar uma de duas aulas do dia não altera a que fica.
(List<Aula>, List<Aula>) _emParesPeloInicio(List<Aula> antes, List<Aula> depois) {
  final semPar = [...depois];
  final pares = <(Aula, Aula)>[];
  final antesSemPar = <Aula>[];
  for (final aula in antes) {
    final i = semPar.indexWhere((outra) => outra.inicio == aula.inicio);
    if (i < 0) {
      antesSemPar.add(aula);
    } else {
      pares.add((aula, semPar.removeAt(i)));
    }
  }
  return ([for (final (a, _) in pares) a, ...antesSemPar], [for (final (_, b) in pares) b, ...semPar]);
}

List<MudancaDeCampo> _mudancas(Aula antes, Aula depois) => [
  for (final (campo, texto) in <(String, String Function(Aula))>[
    ('Início', (aula) => '${aula.inicio}'),
    ('Fim', (aula) => '${aula.fim}'),
    ('Professor', (aula) => aula.professor),
    ('Sala', (aula) => aula.sala),
    ('Andar', _andares),
  ])
    if (texto(antes) != texto(depois)) MudancaDeCampo(campo: campo, antes: texto(antes), depois: texto(depois)),
];

String _andares(Aula aula) => aula.andares.isEmpty ? 'sem andar' : aula.andaresPorExtenso;
