import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/leitor_de_planilha.dart';

/// Planilha salva pelo openpyxl como o Excel salvaria: horários em células de hora, semestre e uma sala como
/// número, coluna de observação e uma linha vazia no meio.
Uint8List gradeDeExemplo() => File('test/planilhas/grade_exemplo.xlsx').readAsBytesSync();

void main() {
  test('lê o cabeçalho e as linhas da primeira aba como texto', () {
    final planilha = lerPlanilhaXlsx(gradeDeExemplo());

    expect(planilha.cabecalho, [
      'Curso',
      'Turno',
      'Semestre',
      'Dia',
      'Início',
      'Fim',
      'Disciplina',
      'Professor',
      'Sala',
      'Andar',
      'Observação',
    ]);
    expect(planilha.linhas.first.take(10), [
      'ADS',
      'Noite',
      '1',
      'Segunda',
      '19:00',
      '20:40',
      'Algoritmos',
      'Ana Souza',
      'B12',
      '1º andar',
    ]);
    expect(planilha.linhas.last.take(10), [
      'Gestão Empresarial',
      'Manhã',
      '2',
      'Terça',
      '7:40',
      '09:20',
      'Contabilidade',
      'José Prado',
      '101',
      'Térreo',
    ]);
  });

  test('a planilha lida passa pela importação sem erros', () {
    final previa = ImportacaoDeGrade(
      RepositorioGradeEmMemoria(),
    ).importar(lerPlanilhaXlsx(gradeDeExemplo()), const SemestreLetivo(ano: 2027, periodo: 1));

    expect([for (final erro in previa.erros) '${erro.linha} ${erro.coluna}: ${erro.mensagem}'], isEmpty);
    expect(previa.quantidadeDeAulas, 4);
  });

  test('arquivo que não é .xlsx gera PlanilhaIlegivel', () {
    expect(
      () => lerPlanilhaXlsx(Uint8List.fromList('não sou uma planilha'.codeUnits)),
      throwsA(isA<PlanilhaIlegivel>()),
    );
  });
}
