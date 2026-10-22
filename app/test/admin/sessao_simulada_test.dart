import 'package:flutter_test/flutter_test.dart';
import 'package:grade_app/admin/sessao.dart';

void main() {
  SessaoSimulada sessao() => SessaoSimulada(email: 'admin@fatecrp.local', senha: 'admin123');

  test('começa sem sessão', () {
    expect(sessao().ativa, isFalse);
  });

  test('e-mail e senha do admin abrem a sessão, sem ligar para maiúsculas no e-mail', () async {
    final simulada = sessao();

    expect(await simulada.entrar(email: ' Admin@FatecRP.local ', senha: 'admin123'), isTrue);
    expect(simulada.ativa, isTrue);
  });

  test('senha errada não abre a sessão', () async {
    final simulada = sessao();

    expect(await simulada.entrar(email: 'admin@fatecrp.local', senha: 'Admin123'), isFalse);
    expect(simulada.ativa, isFalse);
  });

  test('sair encerra a sessão', () async {
    final simulada = sessao();
    await simulada.entrar(email: 'admin@fatecrp.local', senha: 'admin123');

    await simulada.sair();

    expect(simulada.ativa, isFalse);
  });
}
