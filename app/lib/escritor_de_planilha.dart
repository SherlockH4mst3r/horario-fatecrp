import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:grade/grade.dart';

/// Adaptador: escreve a planilha num .xlsx de uma aba, para o admin editar no Excel e importar de volta.
///
/// Número inteiro vira célula de número, e `HH:MM` vira célula de hora, como o admin digitaria; o resto vai como
/// texto. O cabeçalho sai em negrito.
Uint8List escreverPlanilhaXlsx(Planilha planilha, {required String aba}) {
  final arquivo = Excel.createExcel();
  final padrao = arquivo.getDefaultSheet()!;
  arquivo.rename(padrao, aba);
  arquivo.setDefaultSheet(aba);
  final folha = arquivo[aba];

  for (final (coluna, titulo) in planilha.cabecalho.indexed) {
    folha.updateCell(
      CellIndex.indexByColumnRow(columnIndex: coluna, rowIndex: 0),
      TextCellValue(titulo),
      cellStyle: CellStyle(bold: true),
    );
  }
  for (final (indice, linha) in planilha.linhas.indexed) {
    for (final (coluna, texto) in linha.indexed) {
      final valor = _celula(texto);
      folha.updateCell(
        CellIndex.indexByColumnRow(columnIndex: coluna, rowIndex: indice + 1),
        valor,
        cellStyle: valor is TimeCellValue ? CellStyle(numberFormat: NumFormat.defaultTime) : null,
      );
    }
  }
  for (final (coluna, largura) in _larguras.indexed) {
    folha.setColumnWidth(coluna, largura);
  }
  return Uint8List.fromList(arquivo.encode()!);
}

/// Larguras das colunas da importação, na ordem de [colunasDaPlanilha], para caber o texto mais comum.
const _larguras = [10.0, 10.0, 10.0, 11.0, 8.0, 8.0, 34.0, 20.0, 28.0, 20.0];

CellValue? _celula(String texto) {
  if (texto.isEmpty) return null;
  if (RegExp(r'^\d+$').hasMatch(texto)) return IntCellValue(int.parse(texto));
  if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(texto)) {
    final [hora, minuto] = texto.split(':').map(int.parse).toList();
    return TimeCellValue(hour: hora, minute: minuto);
  }
  return TextCellValue(texto);
}
