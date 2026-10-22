import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import 'admin/painel_admin.dart';
import 'admin/sessao.dart';
import 'github/guarda_do_token.dart';
import 'github/repositorio_grade_no_github.dart';
import 'github/repositorio_grade_publicado.dart';
import 'github/sessao_no_github.dart';
import 'grade_semeada.dart';
import 'memoria_no_navegador.dart';
import 'preferencia_de_tema.dart';
import 'repositorio_grade_no_navegador.dart';
import 'tema.dart';
import 'telas/tela_da_grade.dart';

/// O repositório da grade no GitHub, como "dono/nome", passado no build (`--dart-define=GITHUB_REPO=...`), como o
/// GitHub faz ao publicar o site. Sem ele, o site roda a simulação local, com a grade no navegador.
const _repositorioNoGitHub = String.fromEnvironment('GITHUB_REPO');

/// O arquivo da grade no repositório. Fica em `app/web`, para sair junto com o site publicado.
const _caminhoDaGrade = 'app/web/dados/grade.json';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (consulta, painel) = _repositorioNoGitHub.isEmpty ? await _simulacaoLocal() : _peloGitHub();
  runApp(AppDaGrade(consulta: consulta, painelAdmin: painel, preferenciaDeTema: PreferenciaDeTemaNoNavegador()));
}

/// A consulta lê a grade publicada com o site; o painel lê e grava a grade no repositório, com o token do admin.
(ConsultaDeGrade, PainelAdmin) _peloGitHub() {
  final sessao = SessaoNoGitHub(repositorio: _repositorioNoGitHub, guarda: guardaDaAba());
  final noRepositorio = RepositorioGradeNoGitHub(
    repositorio: _repositorioNoGitHub,
    caminho: _caminhoDaGrade,
    token: () => sessao.token,
  );
  return (
    ConsultaDeGrade(
      RepositorioGradePublicado(endereco: Uri.base.resolve('dados/grade.json')),
      memoria: MemoriaNoNavegador(),
    ),
    _painel(sessao, noRepositorio, repositorio: _repositorioNoGitHub),
  );
}

Future<(ConsultaDeGrade, PainelAdmin)> _simulacaoLocal() async {
  final noNavegador = RepositorioGradeNoNavegador();
  await _semearNaPrimeiraVisita(noNavegador);
  return (
    ConsultaDeGrade(noNavegador, memoria: MemoriaNoNavegador()),
    _painel(SessaoSimulada(tokenAceito: 'admin123'), noNavegador, repositorio: null),
  );
}

PainelAdmin _painel(Sessao sessao, RepositorioGrade grade, {required String? repositorio}) => PainelAdmin(
  sessao: sessao,
  repositorio: repositorio,
  importacao: ImportacaoDeGrade(grade),
  edicao: EdicaoDeAulas(grade),
  escolherPlanilha: _escolherPlanilhaNoNavegador,
  salvarPlanilha: _baixarNoNavegador,
);

/// Enquanto não há banco, o navegador começa com a grade semeada; depois, vale o que o admin publicar.
Future<void> _semearNaPrimeiraVisita(RepositorioGrade repositorio) async {
  try {
    if (await repositorio.gradeAtual() == null) await repositorio.substituir(gradeSemeada);
  } catch (_) {
    // Armazenamento bloqueado ou grade ilegível: a tela mostra o aviso de falha ao carregar.
  }
}

Future<Uint8List?> _escolherPlanilhaNoNavegador() async {
  final escolhido = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['xlsx']);
  return escolhido?.readAsBytes();
}

Future<void> _baixarNoNavegador(String nome, Uint8List bytes) async {
  await FilePicker.saveFile(
    fileName: nome,
    bytes: bytes,
    mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}

class AppDaGrade extends StatefulWidget {
  const AppDaGrade({
    super.key,
    required this.consulta,
    this.relogio = DateTime.now,
    this.painelAdmin,
    this.preferenciaDeTema,
  });

  final ConsultaDeGrade consulta;

  /// Os testes trocam por uma data fixa.
  final DateTime Function() relogio;

  /// O painel em `/admin`. Sem ele, o site só tem a consulta pública.
  final Widget? painelAdmin;

  /// Onde o tema escolhido fica guardado; sem ela, a escolha vale só até fechar a página.
  final PreferenciaDeTema? preferenciaDeTema;

  @override
  State<AppDaGrade> createState() => _AppDaGradeState();
}

class _AppDaGradeState extends State<AppDaGrade> {
  late final PreferenciaDeTema _preferencia = widget.preferenciaDeTema ?? PreferenciaDeTemaEmMemoria();
  ThemeMode _tema = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _preferencia.lida().then((tema) {
      if (mounted) setState(() => _tema = tema);
    });
  }

  /// Troca para o tema oposto ao que está na tela e guarda a escolha.
  void _alternar({required bool escuro}) {
    final tema = escuro ? ThemeMode.light : ThemeMode.dark;
    setState(() => _tema = tema);
    _preferencia.guardar(tema);
  }

  @override
  Widget build(BuildContext context) {
    final AppDaGrade(:consulta, :relogio, :painelAdmin) = widget;
    return MaterialApp(
      title: 'Grade de aulas – FATEC RP',
      debugShowCheckedModeBanner: false,
      theme: temaFatec(Brightness.light),
      darkTheme: temaFatec(Brightness.dark),
      themeMode: _tema,
      builder: (context, tela) {
        final tema = Theme.of(context);
        final escuro = tema.brightness == Brightness.dark;
        return ControleDeTema(
          escuro: escuro,
          alternar: () => _alternar(escuro: escuro),
          child: Theme(data: comFonteDaTela(tema, MediaQuery.sizeOf(context).width), child: tela!),
        );
      },
      routes: {
        '/': (_) => TelaDaGrade(consulta: consulta, relogio: relogio),
        if (painelAdmin case final painel?) '/admin': (_) => painel,
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => TelaDaGrade(consulta: consulta, relogio: relogio),
      ),
    );
  }
}
