import 'package:flutter/material.dart';

import 'sessao.dart';

/// A tela de login do painel.
class EntradaDoAdmin extends StatefulWidget {
  const EntradaDoAdmin({super.key, required this.sessao, required this.aoEntrar});

  final Sessao sessao;
  final VoidCallback aoEntrar;

  @override
  State<EntradaDoAdmin> createState() => _EntradaDoAdminState();
}

class _EntradaDoAdminState extends State<EntradaDoAdmin> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _recusada = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final entrou = await widget.sessao.entrar(email: _email.text, senha: _senha.text);
    if (!mounted) return;
    if (entrou) {
      widget.aoEntrar();
    } else {
      setState(() => _recusada = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Acesso do admin', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _entrar(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senha,
              decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
              obscureText: true,
              onSubmitted: (_) => _entrar(),
            ),
            if (_recusada) ...[
              const SizedBox(height: 12),
              Text('E-mail ou senha incorretos.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _entrar, child: const Text('Entrar')),
            const SizedBox(height: 24),
            const _AvisoDeSimulacao(),
          ],
        ),
      ),
    );
  }
}

/// Lembra que o login ainda é de mentira e diz como entrar.
class _AvisoDeSimulacao extends StatelessWidget {
  const _AvisoDeSimulacao();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: cores.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Simulação: o login ainda não está ligado ao Supabase. '
          'Use admin@fatecrp.local e a senha admin123.',
        ),
      ),
    );
  }
}
