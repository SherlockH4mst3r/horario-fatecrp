/// Onde o token do admin fica enquanto a aba está aberta: assim ele não precisa colar de novo a cada recarga, e
/// o token some quando a aba fecha.
abstract interface class GuardaDoToken {
  Future<String?> lido();

  Future<void> guardar(String token);

  Future<void> apagar();
}

/// Guarda o token só na memória do programa. Serve aos testes e a quem roda fora do navegador.
class GuardaDoTokenEmMemoria implements GuardaDoToken {
  String? _token;

  @override
  Future<String?> lido() async => _token;

  @override
  Future<void> guardar(String token) async => _token = token;

  @override
  Future<void> apagar() async => _token = null;
}
