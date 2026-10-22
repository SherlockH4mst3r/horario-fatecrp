# 10: Ligar a grade ao Supabase

**O que entrega:** o site passa a ler a grade do Supabase em vez do repositório em memória, sem mudar nada para o aluno.
**Bloqueado por:** 01
**Status:** wontfix

- [ ] Banco local (`supabase start`) com a tabela de aulas e o mesmo seed do ticket 01.
- [ ] Adaptador Supabase implementa a porta do domínio; domínio e telas não mudam.
- [ ] RLS: visitante anônimo lê as aulas; insert, update e delete anônimos falham (teste de integração no banco).
- [ ] O app escolhe o adaptador por configuração; sem configuração, usa o repositório em memória.

**2026-10-22, decisão nova (docs/adr/0001-publicar-pelo-github.md).** O site vai para o GitHub Pages, a grade fica em `app/web/dados/grade.json` no repositório e o admin entra com um token fino do GitHub. Este ticket fica substituído por essa decisão.
