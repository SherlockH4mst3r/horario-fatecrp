import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import 'admin/painel_admin.dart';
import 'github/guarda_do_token.dart';
import 'github/repositorio_do_site.dart';
import 'github/repositorio_grade_no_github.dart';
import 'github/repositorio_grade_publicado.dart';
import 'github/sessao_no_github.dart';
import 'memoria_no_navegador.dart';
import 'preferencia_de_tema.dart';
import 'tema.dart';
import 'telas/tela_da_grade.dart';

/// O arquivo da grade no repositório. Fica em `app/web`, para sair junto com o site publicado.
const _caminhoDaGrade = 'app/web/dados/grade.json';

/// A consulta lê a grade publicada com o site. O painel lê e grava a grade no repositório de onde o site é
/// publicado, com o token do admin; sem saber que repositório é esse, o site fica só com a consulta.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repositorio = repositorioDoSite(Uri.base, definidoNoBuild: const String.fromEnvironment('GITHUB_REPO'));
  runApp(
    AppDaGrade(
      consulta: ConsultaDeGrade(
        RepositorioGradePublicado(endereco: Uri.base.resolve('dados/grade.json')),
        memoria: MemoriaNoNavegador(),
      ),
      painelAdmin: repositorio == null ? null : _painel(repositorio),
      preferenciaDeTema: PreferenciaDeTemaNoNavegador(),
    ),
  );
}

PainelAdmin _painel(String repositorio) {
  final sessao = SessaoNoGitHub(repositorio: repositorio, guarda: guardaDaAba());
  final noRepositorio = RepositorioGradeNoGitHub(
    repositorio: repositorio,
    caminho: _caminhoDaGrade,
    token: () => sessao.token,
  );
  return PainelAdmin(
    sessao: sessao,
    repositorio: repositorio,
    importacao: ImportacaoDeGrade(noRepositorio),
    edicao: EdicaoDeAulas(noRepositorio),
    escolherPlanilha: _escolherPlanilhaNoNavegador,
    salvarPlanilha: _baixarNoNavegador,
  );
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
