import 'package:grade/grade.dart';
import 'package:test/test.dart';

void main() {
  group('semestre letivo digitado', () {
    test('lê "ano/período", com ou sem espaços', () {
      expect(SemestreLetivo.tentarLer('2027/1')?.rotulo, '2027/1');
      expect(SemestreLetivo.tentarLer(' 2026 / 2 ')?.rotulo, '2026/2');
    });

    test('recusa formato errado e período fora de 1 e 2', () {
      for (final texto in ['', '2027', '2027-1', '27/1', '2027/3', '2027/0', 'abc/1']) {
        expect(SemestreLetivo.tentarLer(texto), isNull, reason: texto);
      }
    });
  });
}
