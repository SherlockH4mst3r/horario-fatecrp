// Confere a grade guardada em JSON com as regras da importação. O GitHub roda isto antes de publicar o site:
// com erro, o comando termina com código 1 e a publicação para.
//
// Uso: dart run bin/conferir_grade.dart <caminho do grade.json>
import 'dart:io';

import 'package:grade/grade.dart';

Future<void> main(List<String> argumentos) async {
  if (argumentos.length != 1) {
    stderr.writeln('Uso: dart run bin/conferir_grade.dart <caminho do grade.json>');
    exit(64);
  }
  final arquivo = File(argumentos.single);
  if (!arquivo.existsSync()) {
    stdout.writeln('Nenhuma grade publicada ainda (${arquivo.path}); nada a conferir.');
    return;
  }
  final Previa previa;
  try {
    previa = await conferirGrade(gradeDoJson(await arquivo.readAsString()));
  } on FormatException catch (erro) {
    stderr.writeln('A grade em ${arquivo.path} não está no formato esperado: ${erro.message}');
    exit(1);
  }
  for (final aviso in previa.avisos) {
    stdout.writeln('Aviso, aula ${aviso.linha - 1} · ${aviso.coluna}: ${aviso.mensagem}');
  }
  if (previa.erros.isNotEmpty) {
    for (final erro in previa.erros) {
      stderr.writeln('Erro, aula ${erro.linha - 1} · ${erro.coluna}: ${erro.mensagem}');
    }
    exit(1);
  }
  stdout.writeln('Grade ${previa.semestreLetivo.rotulo} conferida: ${previa.quantidadeDeAulas} aulas, sem erros.');
}
