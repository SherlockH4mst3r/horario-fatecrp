import 'grade.dart';
import 'importacao_de_grade.dart';
import 'repositorio_grade.dart';

/// Uma aula como o admin a digita no painel: o texto de cada coluna da planilha.
class AulaDigitada {
  const AulaDigitada({
    required this.curso,
    required this.turno,
    required this.semestre,
    required this.dia,
    required this.inicio,
    required this.fim,
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.andar,
  });

  /// A aula publicada como ela seria digitada, para o admin partir dela ao editar.
  factory AulaDigitada.de(Aula aula) => AulaDigitada(
    curso: aula.turma.curso,
    turno: aula.turma.turno.rotulo,
    semestre: '${aula.turma.semestre}',
    dia: aula.dia.rotulo,
    inicio: '${aula.inicio}',
    fim: '${aula.fim}',
    disciplina: aula.disciplina,
    professor: aula.professor,
    sala: aula.sala,
    andar: [for (final andar in aula.andares) andar.rotulo].join('/'),
  );

  final String curso;
  final String turno;
  final String semestre;
  final String dia;
  final String inicio;
  final String fim;
  final String disciplina;
  final String professor;
  final String sala;
  final String andar;

  /// Na ordem de [colunasDaPlanilha].
  List<String> get _comoLinha => [curso, turno, semestre, dia, inicio, fim, disciplina, professor, sala, andar];
}

sealed class ResultadoDaEdicao {
  const ResultadoDaEdicao();
}

class AulaSalva extends ResultadoDaEdicao {
  const AulaSalva(this.aula, {this.avisos = const []});

  final Aula aula;

  /// O que vale a pena conferir, sem impedir a aula: o professor com outra aula no mesmo horário.
  final List<String> avisos;
}

class AulaRecusada extends ResultadoDaEdicao {
  const AulaRecusada(this.erros);

  /// Por coluna da planilha ("Sala", "Início"...), na ordem das colunas; "Grade" quando o problema não é de
  /// um campo.
  final Map<String, String> erros;
}

/// Caso de uso do admin: corrigir uma aula da grade publicada sem reimportar a planilha.
///
/// A aula passa pela mesma validação da importação: a grade publicada vira linhas de planilha, a aula digitada
/// entra como mais uma, e o conjunto é importado. Assim, as regras (campo vazio, horário, conflito de sala,
/// andar...) são as mesmas nos dois caminhos.
class EdicaoDeAulas {
  EdicaoDeAulas(this._repositorio);

  final RepositorioGrade _repositorio;

  /// As turmas que têm aula na grade publicada, em ordem.
  Future<List<Turma>> turmas() async =>
      {for (final aula in (await _repositorio.gradeAtual())?.aulas ?? const <Aula>[]) aula.turma}.toList()..sort();

  /// As aulas da turma na grade publicada, por dia e início.
  Future<List<Aula>> aulasDaTurma(Turma turma) async => [
    for (final aula in (await _repositorio.gradeAtual())?.aulas ?? const <Aula>[])
      if (aula.turma == turma) aula,
  ]..sort((a, b) => a.dia != b.dia ? a.dia.index.compareTo(b.dia.index) : a.inicio.compareTo(b.inicio));

  /// Cria a aula ou, com [original], troca a original por ela.
  Future<ResultadoDaEdicao> salvar(AulaDigitada digitada, {Aula? original}) async {
    final grade = await _repositorio.gradeAtual();
    if (grade == null) {
      return const AulaRecusada({'Grade': 'não há grade publicada: importe uma grade antes de criar aulas'});
    }
    final demais = _sem(grade.aulas, original);
    final importacao = ImportacaoDeGrade(_repositorio);
    final previa = await importacao.importar(
      Planilha(
        cabecalho: colunasDaPlanilha,
        linhas: [for (final aula in demais) AulaDigitada.de(aula)._comoLinha, digitada._comoLinha],
      ),
      grade.semestreLetivo,
    );
    final linhaDigitada = demais.length + 2;
    final errosDaAula = <String, String>{
      for (final erro in previa.erros.reversed)
        if (erro.linha == linhaDigitada) erro.coluna: erro.mensagem,
    };
    if (errosDaAula.isNotEmpty) {
      return AulaRecusada({for (final coluna in colunasDaPlanilha) coluna: ?errosDaAula[coluna]});
    }
    if (previa.erros.firstOrNull case final erro?) {
      return AulaRecusada({'Grade': 'a grade publicada tem um problema na aula ${erro.linha - 1}: ${erro.mensagem}'});
    }
    await importacao.publicar(previa);
    return AulaSalva(
      (await _repositorio.gradeAtual())!.aulas.last,
      avisos: [
        for (final aviso in previa.avisos)
          if (aviso.linha == linhaDigitada) aviso.mensagem,
      ],
    );
  }

  Future<void> excluir(Aula aula) async {
    final grade = await _repositorio.gradeAtual();
    if (grade == null) return;
    await _repositorio.substituir(Grade(semestreLetivo: grade.semestreLetivo, aulas: _sem(grade.aulas, aula)));
  }

  /// As aulas sem a primeira igual a [aula]; todas, se [aula] for `null`.
  List<Aula> _sem(List<Aula> aulas, Aula? aula) {
    final restantes = [...aulas];
    if (aula != null) restantes.remove(aula);
    return restantes;
  }
}
