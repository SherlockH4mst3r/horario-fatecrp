import 'grade.dart';

/// Porta de acesso à grade publicada. Devolve `null` quando nenhuma grade foi publicada.
abstract interface class RepositorioGrade {
  Future<Grade?> gradeAtual();
}
