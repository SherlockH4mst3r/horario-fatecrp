import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import 'grade_semeada.dart';
import 'telas/tela_da_grade.dart';

void main() {
  final consulta = ConsultaDeGrade(RepositorioGradeEmMemoria(gradeSemeada));
  runApp(AppDaGrade(consulta: consulta));
}

class AppDaGrade extends StatelessWidget {
  const AppDaGrade({super.key, required this.consulta});

  final ConsultaDeGrade consulta;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grade de aulas – FATEC RP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFFB20000), useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFFB20000),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: TelaDaGrade(consulta: consulta),
    );
  }
}
