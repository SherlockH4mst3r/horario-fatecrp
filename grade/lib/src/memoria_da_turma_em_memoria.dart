import 'grade.dart';
import 'memoria_da_turma.dart';

/// Adaptador que lembra a turma só enquanto o programa roda. Serve aos testes.
class MemoriaDaTurmaEmMemoria implements MemoriaDaTurma {
  Turma? _turma;

  @override
  Future<Turma?> lembrada() async => _turma;

  @override
  Future<void> guardar(Turma turma) async => _turma = turma;
}
