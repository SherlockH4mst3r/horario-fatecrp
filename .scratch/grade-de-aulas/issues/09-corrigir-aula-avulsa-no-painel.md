# 09: Corrigir aula avulsa no painel

**O que entrega:** o admin cria, edita e exclui uma aula sem reimportar, e o aluno vê a correção na hora.
**Bloqueado por:** 07
**Status:** ready-for-agent

- [x] O painel lista as aulas por turma, com as ações criar, editar e excluir.
- [x] Criar e editar passam pela mesma validação da importação (campo vazio, horário, dia, conflito de sala), com a mensagem no campo.
- [x] Editar a sala para uma já ocupada naquele horário é recusado.
- [x] Excluir pede confirmação antes de apagar.
- [x] Depois de salvar, a grade pública mostra a mudança ao recarregar.

## Comments

**2026-10-22, pronto (com o painel simulado).** `EdicaoDeAulas` (em `grade/lib/src/edicao_de_aulas.dart`) valida a aula digitada pela própria importação: a grade publicada vira linhas de planilha, a aula entra como mais uma, e só os erros da linha dela voltam, por campo. Ao editar, a aula original sai antes da checagem, para não conflitar consigo mesma. No painel, "Corrigir aulas" lista as aulas da turma, com Nova aula, Editar e Excluir (com confirmação). A validação no banco (constraint de conflito) fica para o ticket 10.

**2026-10-22, avisos.** Conflito ou campo inválido aparece numa faixa amarela no topo do formulário, além do erro no campo. Snackbars: verde para sucesso, amarelo para alerta do que o usuário fez (conflito, aviso de professor), vermelho para falha do sistema.
