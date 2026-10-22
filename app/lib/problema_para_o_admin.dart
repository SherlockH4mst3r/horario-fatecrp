/// Uma falha que o próprio admin resolve, como um token expirado ou uma grade que outro admin publicou antes,
/// com a explicação para ele. O painel mostra em amarelo; as demais falhas são do sistema, em vermelho.
abstract interface class ProblemaParaOAdmin implements Exception {
  String get explicacao;
}
