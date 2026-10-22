import 'package:flutter/material.dart';

import '../telas/avisos.dart';
import 'sessao.dart';

/// A tela de login do painel: o admin cola o token do GitHub.
class EntradaDoAdmin extends StatefulWidget {
  const EntradaDoAdmin({super.key, required this.sessao, required this.repositorio, required this.aoEntrar});

  final Sessao sessao;

  /// O repositório da grade, como "dono/nome", para as instruções do token.
  final String repositorio;
  final VoidCallback aoEntrar;

  @override
  State<EntradaDoAdmin> createState() => _EntradaDoAdminState();
}

class _EntradaDoAdminState extends State<EntradaDoAdmin> {
  final _token = TextEditingController();
  ResultadoDaEntrada? _ultima;
  bool _conferindo = false;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() => _conferindo = true);
    final resultado = await widget.sessao.entrar(_token.text);
    if (!mounted) return;
    setState(() {
      _conferindo = false;
      _ultima = resultado;
    });
    if (resultado is EntradaAceita) widget.aoEntrar();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Acesso do admin', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _token,
              decoration: const InputDecoration(labelText: 'Token do GitHub', border: OutlineInputBorder()),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _entrar(),
            ),
            if (_ultima case EntradaRecusada(:final motivo)) ...[
              const SizedBox(height: 12),
              FaixaDeAviso(tipo: TipoDeAviso.alerta, titulo: motivo),
            ] else if (_ultima case EntradaFalhou(:final motivo)) ...[
              const SizedBox(height: 12),
              FaixaDeAviso(tipo: TipoDeAviso.erro, titulo: motivo),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _conferindo ? null : _entrar, child: const Text('Entrar')),
            const SizedBox(height: 24),
            _ComoGerarOToken(widget.repositorio),
          ],
        ),
      ),
    );
  }
}

/// O passo a passo do token fino do GitHub, que só dá acesso a este repositório. Cita só o nome do repositório,
/// e não o dono: o site pode ser publicado por qualquer conta ou organização.
class _ComoGerarOToken extends StatelessWidget {
  const _ComoGerarOToken(this.repositorio);

  /// Como "dono/nome".
  final String repositorio;

  @override
  Widget build(BuildContext context) {
    final nome = repositorio.split('/').last;
    return _Quadro([
      'Para ser admin, peça a quem administra o site acesso de escrita ao repositório $nome no GitHub. '
          'Depois, gere o seu token (uma vez por semestre):',
      '1. No GitHub, abra Settings › Developer settings › Personal access tokens › Fine-grained tokens '
          '(github.com/settings/personal-access-tokens/new).',
      '2. Em "Resource owner", escolha a organização (ou conta) dona do repositório.',
      '3. Em "Repository access", escolha "Only select repositories" e marque o repositório $nome.',
      '4. Em "Permissions", dê a "Contents" o acesso "Read and write".',
      '5. Em "Expiration", escolha o fim do semestre. Gere o token e cole aqui.',
      'O token fica só nesta aba e some quando ela fecha. Não o envie a ninguém.',
    ]);
  }
}

class _Quadro extends StatelessWidget {
  const _Quadro(this.linhas);

  final List<String> linhas;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: cores.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SelectableText.rich(
          TextSpan(children: [for (final (i, linha) in linhas.indexed) TextSpan(text: i == 0 ? linha : '\n$linha')]),
        ),
      ),
    );
  }
}
