# 07: Bloquear planilha com erro

**O que entrega:** a prévia aponta cada erro pela linha da planilha e não deixa publicar enquanto houver erro.
**Bloqueado por:** 06
**Status:** ready-for-agent

- [ ] Campo vazio gera erro com o número da linha e o nome da coluna.
- [ ] Horário em formato inválido, ou fim antes do início, gera erro na linha.
- [ ] Dia fora de segunda a sábado (incluindo domingo) gera erro na linha.
- [ ] Andar fora de Térreo, 1º, 2º e 3º gera erro na linha.
- [ ] A mesma sala com andares diferentes em linhas distintas gera erro nessas linhas.
- [ ] Duas aulas na mesma sala, no mesmo dia e com horários sobrepostos geram erro nas duas linhas.
- [ ] Aulas na mesma sala que só se encostam (uma termina às 19:00 e a outra começa às 19:00) não geram erro.
- [ ] Com qualquer erro, "Publicar" fica desabilitado.
- [ ] A exclusion constraint no banco recusa a inserção de aulas com conflito de sala, mesmo fora do app (teste de integração no banco).

## Comments

**2026-10-22, domínio pronto.** A prévia aponta linha e coluna de: campo vazio, coluna faltando no cabeçalho, horário inválido, fim antes do início ou igual a ele, dia fora de segunda a sábado, turno, semestre e andar inválidos, conflito de sala (erro nas duas linhas; aulas que só se encostam passam) e sala em andares diferentes. Com erro, `publicar` recusa a prévia. Faltam: botão "Publicar" desabilitado no painel e a exclusion constraint no banco.

**2026-10-22, salas duplas e salas a definir.** A coluna Andar aceita um andar por sala ("1º andar/3º andar" para "S4/L3"), ou um só para todas. Novos erros: número de andares diferente do número de salas. A checagem de "sala em andares diferentes" olha cada sala sozinha (a L1 de "L1/S2" é a mesma L1 de outra linha). Sala a definir ("A definir – ...") pode vir sem andar.

**2026-10-22, conflitos de turma e de professor.** A mesma turma com duas aulas ao mesmo tempo é erro (coluna Início, nas duas linhas). O mesmo professor em duas aulas ao mesmo tempo é aviso: aparece na prévia, mas não impede publicar (a grade oficial de 2026/2 tem dois casos, do mesmo professor). As mensagens de conflito dizem com qual aula a linha se choca e em que linha ela está.
