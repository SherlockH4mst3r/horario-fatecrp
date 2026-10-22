# 05: Entrar no painel admin

**O que entrega:** o admin entra em `/admin` com e-mail e senha e sai quando quiser; sem login, ninguém escreve na grade.
**Bloqueado por:** 01, 10
**Status:** ready-for-agent

- [ ] `/admin` sem sessão mostra a tela de login.
- [ ] E-mail e senha de um admin criado no Supabase abrem o painel.
- [ ] Senha errada mostra mensagem de erro e não abre o painel.
- [ ] Auto-cadastro está desligado: não há tela de cadastro, e o signup pela API falha.
- [ ] RLS: admin autenticado insere, edita e exclui aulas; anônimo continua só lendo (teste de integração no banco).
- [ ] "Sair" encerra a sessão e volta à tela de login.
- [ ] A tela pública não mostra link nem botão do painel.

## Comments

**2026-10-22, painel simulado.** Enquanto não há Supabase, `/#/admin` usa a porta `Sessao` (em `app/lib/admin/sessao.dart`) com `SessaoSimulada`: um admin fixo (admin@fatecrp.local / admin123), sessão só enquanto a página está aberta. A grade fica no localStorage (`RepositorioGradeNoNavegador`), então o que o painel publica aparece na consulta pública ao recarregar. Já valem: tela de login sem sessão, senha errada com mensagem, "Sair", e nenhum link do painel na tela pública. Faltam: login e RLS do Supabase e o teste de integração no banco (ticket 10).
