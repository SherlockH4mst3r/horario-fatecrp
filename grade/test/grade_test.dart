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

  test('a turma se apresenta como curso, turno e semestre', () {
    expect(const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3).rotulo, 'ADS – Noite – 3º');
  });

  group('andares por extenso', () {
    Aula aula(List<Andar> andares) => Aula(
      turma: const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3),
      dia: DiaDaSemana.segunda,
      inicio: Horario.parse('19:00'),
      fim: Horario.parse('20:40'),
      disciplina: 'BD',
      professor: 'Rita',
      sala: 'S4/L3',
      andares: andares,
    );

    test('um andar por sala; um só quando ficam no mesmo; vazio na sala a definir', () {
      expect(aula([Andar.primeiro, Andar.terceiro]).andaresPorExtenso, '1º andar/3º andar');
      expect(aula([Andar.primeiro, Andar.primeiro]).andaresPorExtenso, '1º andar');
      expect(aula(const []).andaresPorExtenso, '');
    });
  });
}
