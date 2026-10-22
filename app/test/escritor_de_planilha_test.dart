import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/escritor_de_planilha.dart';
import 'package:grade_app/leitor_de_planilha.dart';

void main() {
  final planilha = Planilha(
    cabecalho: colunasDaPlanilha,
    linhas: [
      ['ADS', 'Noite', '3', 'Segunda', '19:00', '20:40', 'Banco de Dados', 'Rita Alves', 'L1/S2', '1º andar/1º andar'],
      ['GRH', 'Manhã', '1', 'Sexta', '07:40', '09:20', 'COM EMP', 'CARLOS N', 'A definir – GRH Manhã 1º', ''],
    ],
  );

  test('o .xlsx escrito volta igual pelo leitor', () {
    final lida = lerPlanilhaXlsx(escreverPlanilhaXlsx(planilha, aba: 'Grade 2026-2'));

    expect(lida.cabecalho, planilha.cabecalho);
    expect(lida.linhas, planilha.linhas);
  });

  test('semestre vira número e horário vira célula de hora, como o admin espera no Excel', () {
    final aba = Excel.decodeBytes(escreverPlanilhaXlsx(planilha, aba: 'Grade 2026-2')).tables['Grade 2026-2']!;
    final primeira = aba.rows[1];

    expect(primeira[2]?.value, const IntCellValue(3));
    expect(primeira[4]?.value, const TimeCellValue(hour: 19));
    expect(primeira[8]?.value, TextCellValue('L1/S2'));
  });
}
