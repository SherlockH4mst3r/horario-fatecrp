import 'grade.dart';
import 'repositorio_grade.dart';

/// Adaptador que guarda a grade em memória. Serve aos testes e ao site enquanto não há banco.
class RepositorioGradeEmMemoria implements RepositorioGrade {
  RepositorioGradeEmMemoria([this._grade]);

  final Grade? _grade;

  @override
  Future<Grade?> gradeAtual() async => _grade;
}
