import 'package:grade/grade.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adaptador que guarda a grade publicada no navegador (localStorage, na web), no lugar do banco enquanto o
/// site não está ligado ao Supabase. O painel e a consulta pública do mesmo navegador veem a mesma grade.
class RepositorioGradeNoNavegador implements RepositorioGrade {
  static const _chave = 'grade';

  @override
  Future<Grade?> gradeAtual() async {
    final guardado = await SharedPreferences.getInstance();
    // Relê o navegador: outra aba (o painel, por exemplo) pode ter publicado desde a última leitura.
    await guardado.reload();
    final guardada = guardado.getString(_chave);
    if (guardada == null) return null;
    return gradeDoJson(guardada);
  }

  @override
  Future<void> substituir(Grade grade) async {
    final guardado = await SharedPreferences.getInstance();
    await guardado.setString(_chave, gradeComoJson(grade));
  }
}
