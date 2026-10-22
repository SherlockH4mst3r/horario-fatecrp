import 'grade.dart';

/// Porta de acesso à grade publicada.
abstract interface class RepositorioGrade {
  /// Devolve `null` quando nenhuma grade foi publicada.
  Future<Grade?> gradeAtual();

  /// Troca a grade publicada inteira pela nova, tudo ou nada.
  Future<void> substituir(Grade grade);
}
