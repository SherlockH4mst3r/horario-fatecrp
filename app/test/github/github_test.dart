import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade/grade.dart';
import 'package:grade_app/admin/sessao.dart';
import 'package:grade_app/github/guarda_do_token.dart';
import 'package:grade_app/github/repositorio_grade_no_github.dart';
import 'package:grade_app/github/repositorio_grade_publicado.dart';
import 'package:grade_app/github/sessao_no_github.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const repositorio = 'SherlockH4mst3r/horario-fatecrp';
const caminho = 'app/web/dados/grade.json';

final grade = Grade(
  semestreLetivo: const SemestreLetivo(ano: 2026, periodo: 2),
  aulas: [
    Aula(
      turma: const Turma(curso: 'ADS', turno: Turno.noite, semestre: 3),
      dia: DiaDaSemana.quarta,
      inicio: Horario.parse('19:00'),
      fim: Horario.parse('22:30'),
      disciplina: 'Banco de Dados',
      professor: 'Rita Alves',
      sala: 'S14',
      andares: const [Andar.segundo],
    ),
  ],
);

http.Response json(Object corpo, [int status = 200]) =>
    http.Response(jsonEncode(corpo), status, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('sessão pelo token', () {
    late List<http.Request> pedidos;

    SessaoNoGitHub sessao(http.Response Function(http.Request pedido) responder, {GuardaDoToken? guarda}) {
      pedidos = [];
      return SessaoNoGitHub(
        repositorio: repositorio,
        guarda: guarda ?? GuardaDoTokenEmMemoria(),
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          return responder(pedido);
        }),
      );
    }

    http.Response gitHubQueAceita(http.Request pedido) => switch (pedido.url.path) {
      '/repos/$repositorio' => json({
        'permissions': {'push': true},
      }),
      '/user' => json({'login': 'SherlockH4mst3r'}),
      _ => json({}, 404),
    };

    test('token com acesso de escrita ao repositório abre a sessão, com o nome da conta', () async {
      final simulada = sessao(gitHubQueAceita);

      final resultado = await simulada.entrar('  github_pat_abc  ');

      expect(resultado, isA<EntradaAceita>().having((r) => r.quem, 'quem', 'SherlockH4mst3r'));
      expect(simulada.ativa, isTrue);
      expect(simulada.token, 'github_pat_abc');
      expect(pedidos.first.headers['authorization'], 'Bearer github_pat_abc');
    });

    test('token que o GitHub não reconhece é recusado', () async {
      final simulada = sessao((_) => json({'message': 'Bad credentials'}, 401));

      final resultado = await simulada.entrar('errado');

      expect(resultado, isA<EntradaRecusada>().having((r) => r.motivo, 'motivo', contains('não reconheceu o token')));
      expect(simulada.ativa, isFalse);
    });

    test('token sem acesso ao repositório é recusado', () async {
      final simulada = sessao((_) => json({'message': 'Not Found'}, 404));

      final resultado = await simulada.entrar('outro_repo');

      expect(
        resultado,
        isA<EntradaRecusada>().having(
          (r) => r.motivo,
          'motivo',
          allOf(contains('horario-fatecrp'), isNot(contains('SherlockH4mst3r'))),
        ),
      );
    });

    test('conta que só lê o repositório é recusada', () async {
      final simulada = sessao(
        (pedido) => json({
          'permissions': {'push': false},
        }),
      );

      final resultado = await simulada.entrar('so_leitura');

      expect(resultado, isA<EntradaRecusada>().having((r) => r.motivo, 'motivo', contains('não pode escrever')));
    });

    test('GitHub fora do ar é falha do sistema, não do token', () async {
      final simulada = sessao((_) => http.Response('', 503));

      expect(await simulada.entrar('qualquer'), isA<EntradaFalhou>());
    });

    test('o token fica guardado até sair, e a sessão é retomada ao reabrir a página', () async {
      final guarda = GuardaDoTokenEmMemoria();
      await sessao(gitHubQueAceita, guarda: guarda).entrar('github_pat_abc');

      final reaberta = sessao(gitHubQueAceita, guarda: guarda);
      expect(await reaberta.retomar(), isA<EntradaAceita>());
      expect(reaberta.ativa, isTrue);

      await reaberta.sair();
      expect(reaberta.ativa, isFalse);
      expect(await guarda.lido(), isNull);
    });

    test('sem token guardado, não há sessão para retomar', () async {
      expect(await sessao(gitHubQueAceita).retomar(), isNull);
    });
  });

  group('grade no repositório', () {
    late List<http.Request> pedidos;
    late Map<String, Object?> arquivo;

    RepositorioGradeNoGitHub repositorioNoGitHub(http.Response Function(http.Request pedido) responder) {
      pedidos = [];
      return RepositorioGradeNoGitHub(
        repositorio: repositorio,
        caminho: caminho,
        token: () => 'github_pat_abc',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          return responder(pedido);
        }),
      );
    }

    http.Response comArquivo(http.Request pedido) => switch (pedido.method) {
      'GET' => json(arquivo),
      'PUT' => json({
        'content': {'sha': 'sha-novo'},
      }),
      _ => json({}, 405),
    };

    setUp(() {
      arquivo = {'sha': 'sha-1', 'content': base64.encode(utf8.encode(gradeComoJson(grade))).replaceAll('A', 'A\n')};
    });

    test('lê a grade do arquivo no repositório, com o token', () async {
      final lida = await repositorioNoGitHub(comArquivo).gradeAtual();

      expect(lida!.aulas, grade.aulas);
      expect(pedidos.single.url.path, '/repos/$repositorio/contents/$caminho');
      expect(pedidos.single.headers['authorization'], 'Bearer github_pat_abc');
    });

    test('sem o arquivo no repositório, não há grade publicada', () async {
      expect(await repositorioNoGitHub((_) => json({}, 404)).gradeAtual(), isNull);
    });

    test('publicar grava o arquivo num commit, a partir da versão lida', () async {
      final noGitHub = repositorioNoGitHub(comArquivo);
      await noGitHub.gradeAtual();

      await noGitHub.substituir(grade);

      final gravacao = pedidos.last;
      final corpo = jsonDecode(gravacao.body) as Map<String, Object?>;
      expect(gravacao.method, 'PUT');
      expect(corpo['sha'], 'sha-1');
      expect(corpo['branch'], 'main');
      expect(corpo['message'], 'Publica a grade 2026/2 pelo painel');
      expect(gradeDoJson(utf8.decode(base64.decode(corpo['content']! as String))).aulas, grade.aulas);
    });

    test('a primeira publicação cria o arquivo, sem versão anterior', () async {
      final noGitHub = repositorioNoGitHub(
        (pedido) => pedido.method == 'GET'
            ? json({}, 404)
            : json({
                'content': {'sha': 'sha-novo'},
              }, 201),
      );
      await noGitHub.gradeAtual();

      await noGitHub.substituir(grade);

      expect((jsonDecode(pedidos.last.body) as Map).containsKey('sha'), isFalse);
    });

    test('se a grade mudou no GitHub desde a leitura, publicar avisa o conflito', () async {
      final noGitHub = repositorioNoGitHub(
        (pedido) => pedido.method == 'GET' ? json(arquivo) : json({'message': 'sha does not match'}, 409),
      );
      await noGitHub.gradeAtual();

      await expectLater(noGitHub.substituir(grade), throwsA(isA<GradeMudouNoGitHub>()));
    });

    test('token que perdeu a permissão de escrita é recusado ao publicar', () async {
      final noGitHub = repositorioNoGitHub(
        (pedido) => pedido.method == 'GET' ? json(arquivo) : json({'message': 'Resource not accessible'}, 403),
      );
      await noGitHub.gradeAtual();

      await expectLater(noGitHub.substituir(grade), throwsA(isA<SemPermissaoNoGitHub>()));
    });
  });

  group('grade publicada no site', () {
    test('a consulta pública lê o grade.json que saiu junto com o site, sem token e sem cache', () async {
      final pedidos = <http.Request>[];
      final publicado = RepositorioGradePublicado(
        endereco: Uri.parse('https://sherlockh4mst3r.github.io/horario-fatecrp/dados/grade.json'),
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          return http.Response.bytes(utf8.encode(gradeComoJson(grade)), 200);
        }),
      );

      expect((await publicado.gradeAtual())!.aulas, grade.aulas);
      expect(pedidos.single.url.path, '/horario-fatecrp/dados/grade.json');
      expect(pedidos.single.url.queryParameters, contains('v'));
      expect(pedidos.single.headers.containsKey('authorization'), isFalse);
    });

    test('antes da primeira publicação, não há grade', () async {
      final publicado = RepositorioGradePublicado(
        endereco: Uri.parse('https://exemplo/dados/grade.json'),
        cliente: MockClient((_) async => http.Response('', 404)),
      );

      expect(await publicado.gradeAtual(), isNull);
    });

    test('a consulta pública não escreve na grade', () async {
      final publicado = RepositorioGradePublicado(
        endereco: Uri.parse('https://exemplo/dados/grade.json'),
        cliente: MockClient((_) async => http.Response('', 404)),
      );

      expect(() => publicado.substituir(grade), throwsUnsupportedError);
    });
  });
}
