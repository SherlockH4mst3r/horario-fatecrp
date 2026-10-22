/// O endereço e os cabeçalhos da API REST do GitHub, comuns à sessão e ao repositório.
final apiDoGitHub = Uri.parse('https://api.github.com');

Map<String, String> cabecalhosDoGitHub(String token) => {
  'Authorization': 'Bearer $token',
  'Accept': 'application/vnd.github+json',
  'X-GitHub-Api-Version': '2022-11-28',
};

/// Um parâmetro que muda a cada pedido, para o navegador não devolver uma resposta guardada em cache.
Map<String, String> semCache() => {'v': '${DateTime.now().millisecondsSinceEpoch}'};
