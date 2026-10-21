# 07: Bloquear planilha com erro

**O que entrega:** a prévia aponta cada erro pela linha da planilha e não deixa publicar enquanto houver erro.
**Bloqueado por:** 06
**Status:** ready-for-agent

- [ ] Campo vazio gera erro com o número da linha e o nome da coluna.
- [ ] Horário em formato inválido, ou fim antes do início, gera erro na linha.
- [ ] Dia fora de segunda a sábado (incluindo domingo) gera erro na linha.
- [ ] Duas aulas na mesma sala, no mesmo dia e com horários sobrepostos geram erro nas duas linhas.
- [ ] Aulas na mesma sala que só se encostam (uma termina às 19:00 e a outra começa às 19:00) não geram erro.
- [ ] Com qualquer erro, "Publicar" fica desabilitado.
- [ ] A exclusion constraint no banco recusa a inserção de aulas com conflito de sala, mesmo fora do app (teste de integração no banco).
