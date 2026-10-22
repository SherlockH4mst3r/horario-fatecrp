import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/memoria_no_navegador.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const ads3 = Turma(curso: 'ADS', turno: Turno.noite, semestre: 3);

  test('guarda a turma e a devolve na próxima leitura', () async {
    SharedPreferences.setMockInitialValues({});

    await MemoriaNoNavegador().guardar(ads3);

    expect(await MemoriaNoNavegador().lembrada(), ads3);
  });

  test('sem nada guardado, não lembra turma', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await MemoriaNoNavegador().lembrada(), isNull);
  });

  test('dado guardado fora do formato conta como nada guardado', () async {
    SharedPreferences.setMockInitialValues({'turma': '{"curso": "ADS", "turno": "madrugada", "semestre": 3}'});

    expect(await MemoriaNoNavegador().lembrada(), isNull);
  });
}
