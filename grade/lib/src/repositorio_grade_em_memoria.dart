import 'grade.dart';
import 'repositorio_grade.dart';

/// Adaptador que guarda a grade em memória. Serve aos testes e ao site enquanto não há banco.
class RepositorioGradeEmMemoria implements RepositorioGrade {
  RepositorioGradeEmMemoria([this._grade]);

  Grade? _grade;

  @override
  Future<Grade?> gradeAtual() async => _grade;

  @override
  Future<void> substituir(Grade grade) async => _grade = grade;
}
