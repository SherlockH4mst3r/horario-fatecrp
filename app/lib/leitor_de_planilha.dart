import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:grade/grade.dart';

/// O arquivo enviado não pôde ser aberto como planilha .xlsx.
class PlanilhaIlegivel implements Exception {
  const PlanilhaIlegivel(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'PlanilhaIlegivel: $mensagem';
}

/// Adaptador: converte a primeira aba de um .xlsx em texto, linha 1 como cabeçalho. Não valida nada; isso cabe
/// à importação.
///
/// Cada célula vira o texto que o admin vê no Excel: hora como `HH:MM`, número inteiro sem casas decimais e
/// célula vazia como texto vazio.
Planilha lerPlanilhaXlsx(Uint8List bytes) {
  final Excel arquivo;
  try {
    arquivo = Excel.decodeBytes(_compativelComOPacoteExcel(bytes));
  } catch (_) {
    throw const PlanilhaIlegivel('o arquivo não é uma planilha .xlsx');
  }
  final aba = arquivo.tables[arquivo.getDefaultSheet()] ?? arquivo.tables.values.firstOrNull;
  if (aba == null || aba.rows.isEmpty) throw const PlanilhaIlegivel('a planilha está vazia');

  final [cabecalho, ...linhas] = [
    for (final linha in aba.rows) [for (final celula in linha) _comoTexto(celula?.value)],
  ];
  return Planilha(cabecalho: cabecalho, linhas: linhas);
}

/// O pacote excel tropeça em dois jeitos válidos de gravar .xlsx, comuns no openpyxl e em outras ferramentas:
/// - caminho absoluto para as abas (`/xl/worksheets/...`), em vez do relativo que o Excel grava;
/// - célula de texto vazia gravada como `<c t="inlineStr"/>`, sem o texto dentro.
/// Aqui os dois viram o jeito que o pacote entende, antes da leitura.
List<int> _compativelComOPacoteExcel(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  final corrigido = Archive();
  var mudou = false;
  for (final arquivo in zip.files) {
    final original = switch (_correcaoPara(arquivo.name)) {
      final corrigir? => (texto: utf8.decode(arquivo.content as List<int>), corrigir: corrigir),
      null => null,
    };
    final novo = original?.corrigir(original.texto);
    if (original == null || novo == original.texto) {
      corrigido.addFile(arquivo);
      continue;
    }
    mudou = true;
    final conteudo = utf8.encode(novo!);
    corrigido.addFile(ArchiveFile(arquivo.name, conteudo.length, conteudo));
  }
  return mudou ? ZipEncoder().encode(corrigido)! : bytes;
}

String Function(String xml)? _correcaoPara(String caminho) {
  if (caminho == 'xl/_rels/workbook.xml.rels') return (xml) => xml.replaceAll('Target="/xl/', 'Target="');
  if (caminho.startsWith('xl/worksheets/') && caminho.endsWith('.xml')) {
    return (xml) => xml.replaceAll(RegExp(r'\s+t="inlineStr"\s*/>'), '/>');
  }
  return null;
}

String _comoTexto(CellValue? valor) => switch (valor) {
  null => '',
  TextCellValue(:final value) => value.toString(),
  IntCellValue(:final value) => '$value',
  DoubleCellValue(:final value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value',
  TimeCellValue(:final hour, :final minute, :final second) => _hora(hour, minute, second),
  // O Excel guarda hora sem data como data de 1899/1900; só a hora interessa.
  DateTimeCellValue(:final year, :final hour, :final minute, :final second) when year <= 1900 => _hora(
    hour,
    minute,
    second,
  ),
  DateTimeCellValue(:final day, :final month, :final year, :final hour, :final minute) =>
    '${_doisDigitos(day)}/${_doisDigitos(month)}/$year ${_hora(hour, minute, 0)}',
  DateCellValue(:final day, :final month, :final year) => '${_doisDigitos(day)}/${_doisDigitos(month)}/$year',
  BoolCellValue(:final value) => value ? 'VERDADEIRO' : 'FALSO',
  FormulaCellValue(:final formula) => '=$formula',
};

/// Arredonda para o minuto mais próximo: o Excel guarda hora como fração do dia, e 19:00 pode chegar como
/// 18:59:59.
String _hora(int hora, int minuto, int segundo) {
  final minutosDoDia = hora * 60 + minuto + (segundo >= 30 ? 1 : 0);
  return '${_doisDigitos(minutosDoDia ~/ 60 % 24)}:${_doisDigitos(minutosDoDia % 60)}';
}

String _doisDigitos(int numero) => numero.toString().padLeft(2, '0');
