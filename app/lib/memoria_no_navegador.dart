import 'dart:convert';

import 'package:grade/grade.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adaptador que guarda a última turma escolhida no navegador (localStorage, na web).
///
/// A turma vai numa chave só: uma gravação interrompida nunca mistura o curso de uma escolha
/// com o semestre de outra.
class MemoriaNoNavegador implements MemoriaDaTurma {
  static const _chave = 'turma';

  @override
  Future<Turma?> lembrada() async {
    final guardado = (await SharedPreferences.getInstance()).getString(_chave);
    if (guardado == null) return null;
    if (jsonDecode(guardado) case {'curso': String curso, 'turno': String turno, 'semestre': int semestre}) {
      if (Turno.values.asNameMap()[turno] case final turno?) {
        return Turma(curso: curso, turno: turno, semestre: semestre);
      }
    }
    return null;
  }

  @override
  Future<void> guardar(Turma turma) async {
    final guardado = await SharedPreferences.getInstance();
    await guardado.setString(
      _chave,
      jsonEncode({'curso': turma.curso, 'turno': turma.turno.name, 'semestre': turma.semestre}),
    );
  }
}
