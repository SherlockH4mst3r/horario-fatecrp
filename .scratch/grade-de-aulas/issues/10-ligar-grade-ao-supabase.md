# 10: Ligar a grade ao Supabase

**O que entrega:** o site passa a ler a grade do Supabase em vez do repositório em memória, sem mudar nada para o aluno.
**Bloqueado por:** 01
**Status:** ready-for-agent

- [ ] Banco local (`supabase start`) com a tabela de aulas e o mesmo seed do ticket 01.
- [ ] Adaptador Supabase implementa a porta do domínio; domínio e telas não mudam.
- [ ] RLS: visitante anônimo lê as aulas; insert, update e delete anônimos falham (teste de integração no banco).
- [ ] O app escolhe o adaptador por configuração; sem configuração, usa o repositório em memória.
