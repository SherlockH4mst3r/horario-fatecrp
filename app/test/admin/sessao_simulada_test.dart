import 'package:flutter_test/flutter_test.dart';
import 'package:grade_app/admin/sessao.dart';

void main() {
  SessaoSimulada sessao() => SessaoSimulada(tokenAceito: 'admin123');

  test('começa sem sessão', () {
    expect(sessao().ativa, isFalse);
  });

  test('o token aceito abre a sessão, mesmo com espaços em volta', () async {
    final simulada = sessao();

    expect(await simulada.entrar(' admin123 '), isA<EntradaAceita>());
    expect(simulada.ativa, isTrue);
  });

  test('outro token é recusado', () async {
    final simulada = sessao();

    expect(await simulada.entrar('Admin123'), isA<EntradaRecusada>());
    expect(simulada.ativa, isFalse);
  });

  test('sair encerra a sessão', () async {
    final simulada = sessao();
    await simulada.entrar('admin123');

    await simulada.sair();

    expect(simulada.ativa, isFalse);
  });
}
