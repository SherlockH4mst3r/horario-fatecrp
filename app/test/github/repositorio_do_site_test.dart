import 'package:flutter_test/flutter_test.dart';
import 'package:grade_app/github/repositorio_do_site.dart';

void main() {
  test('o repositório passado no build vale primeiro, como o GitHub faz ao publicar', () {
    final repositorio = repositorioDoSite(
      Uri.parse('https://qualquer.github.io/outro/'),
      definidoNoBuild: 'fatecrp-horario/horario-fatecrp',
    );

    expect(repositorio, 'fatecrp-horario/horario-fatecrp');
  });

  test('sem ele, o repositório sai do endereço do GitHub Pages', () {
    expect(
      repositorioDoSite(Uri.parse('https://fatecrp-horario.github.io/horario-fatecrp/#/admin')),
      'fatecrp-horario/horario-fatecrp',
    );
  });

  test('o site na raiz da conta usa o repositório dono.github.io', () {
    expect(
      repositorioDoSite(Uri.parse('https://fatecrp-horario.github.io/')),
      'fatecrp-horario/fatecrp-horario.github.io',
    );
  });

  test('fora do GitHub Pages e sem build configurado, não há repositório', () {
    expect(repositorioDoSite(Uri.parse('http://127.0.0.1:8765/#/admin')), isNull);
    expect(repositorioDoSite(Uri.parse('https://horario.fatecrp.edu.br/')), isNull);
  });

  test('valor do build fora do formato dono/nome é ignorado', () {
    expect(repositorioDoSite(Uri.parse('http://127.0.0.1:8765/'), definidoNoBuild: 'sem-barra'), isNull);
  });
}
