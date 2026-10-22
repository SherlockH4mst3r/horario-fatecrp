/// O repositório da grade, como "dono/nome", sem nome fixo no código: quem publicar o site (a conta atual, uma
/// organização, um fork da Fatec) usa o próprio repositório.
///
/// Vale primeiro o que o build recebeu ([definidoNoBuild], de `--dart-define=GITHUB_REPO=dono/nome`, que o
/// GitHub passa ao publicar). Sem ele, o repositório sai do endereço do GitHub Pages
/// (`https://dono.github.io/nome/`). Fora do Pages e sem o build configurado, não há repositório: `null`.
String? repositorioDoSite(Uri endereco, {String definidoNoBuild = ''}) {
  if (RegExp(r'^[\w.-]+/[\w.-]+$').hasMatch(definidoNoBuild)) return definidoNoBuild;
  final dono = RegExp(r'^([\w-]+)\.github\.io$').firstMatch(endereco.host)?[1];
  if (dono == null) return null;
  final nome = endereco.pathSegments.where((parte) => parte.isNotEmpty).firstOrNull ?? '$dono.github.io';
  return '$dono/$nome';
}
