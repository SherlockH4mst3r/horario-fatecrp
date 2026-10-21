# 06: Importar planilha válida

**O que entrega:** o admin envia o .xlsx do semestre letivo, confere a prévia e publica; os alunos passam a ver a grade nova.
**Bloqueado por:** 05
**Status:** ready-for-agent

- [ ] O painel aceita um arquivo .xlsx com uma linha por aula: curso, turno, semestre, dia, início, fim, disciplina, professor e sala.
- [ ] O admin informa o semestre letivo (ex.: 2026/2) antes da prévia.
- [ ] A prévia lista as turmas e as salas encontradas na planilha.
- [ ] "Cancelar" na prévia não altera a grade publicada.
- [ ] "Publicar" substitui a grade inteira, e o topo do site passa a mostrar o novo semestre letivo.
- [ ] A substituição é tudo ou nada: se a inserção falha no meio, a grade anterior continua intacta (teste de integração no banco).
- [ ] O domínio `importar` é testado com linhas brutas em memória; o leitor de .xlsx tem um teste de fumaça com um arquivo de exemplo.
