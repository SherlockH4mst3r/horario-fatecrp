# 09: Corrigir aula avulsa no painel

**O que entrega:** o admin cria, edita e exclui uma aula sem reimportar, e o aluno vê a correção na hora.
**Bloqueado por:** 07
**Status:** ready-for-agent

- [ ] O painel lista as aulas por turma, com as ações criar, editar e excluir.
- [ ] Criar e editar passam pela mesma validação da importação (campo vazio, horário, dia, conflito de sala), com a mensagem no campo.
- [ ] Editar a sala para uma já ocupada naquele horário é recusado.
- [ ] Excluir pede confirmação antes de apagar.
- [ ] Depois de salvar, a grade pública mostra a mudança ao recarregar.
