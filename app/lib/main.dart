import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import 'grade_semeada.dart';
import 'memoria_no_navegador.dart';
import 'tema.dart';
import 'telas/tela_da_grade.dart';

void main() {
  final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria(gradeSemeada), memoria: MemoriaNoNavegador());
  runApp(AppDaGrade(consulta: consulta));
}

class AppDaGrade extends StatelessWidget {
  const AppDaGrade({super.key, required this.consulta, this.relogio = DateTime.now});

  final ConsultaDeGrade consulta;

  /// Os testes trocam por uma data fixa.
  final DateTime Function() relogio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grade de aulas – FATEC RP',
      debugShowCheckedModeBanner: false,
      theme: temaFatec(Brightness.light),
      darkTheme: temaFatec(Brightness.dark),
      home: TelaDaGrade(consulta: consulta, relogio: relogio),
    );
  }
}
