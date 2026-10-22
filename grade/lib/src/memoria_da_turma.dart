import 'grade.dart';

/// Porta para lembrar a última turma que o aluno escolheu. Devolve `null` quando nada foi guardado.
/// Pode falhar (ex.: navegador que bloqueia o armazenamento); quem usa trata a falha como "nada guardado".
abstract interface class MemoriaDaTurma {
  Future<Turma?> lembrada();

  Future<void> guardar(Turma turma);
}
