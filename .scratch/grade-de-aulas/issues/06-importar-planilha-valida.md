# 06: Importar planilha válida

**O que entrega:** o admin envia o .xlsx do semestre letivo, confere a prévia e publica; os alunos passam a ver a grade nova.
**Bloqueado por:** 05
**Status:** ready-for-agent

- [ ] O painel aceita um arquivo .xlsx com uma linha por aula: curso, turno, semestre, dia, início, fim, disciplina, professor, sala e andar.
- [ ] O admin informa o semestre letivo (ex.: 2026/2) antes da prévia.
- [ ] A prévia lista as turmas e as salas encontradas na planilha.
- [ ] "Cancelar" na prévia não altera a grade publicada.
- [ ] "Publicar" substitui a grade inteira, e o topo do site passa a mostrar o novo semestre letivo.
- [ ] A substituição é tudo ou nada: se a inserção falha no meio, a grade anterior continua intacta (teste de integração no banco).
- [ ] O domínio `importar` é testado com linhas brutas em memória; o leitor de .xlsx tem um teste de fumaça com um arquivo de exemplo.

## Comments

**2026-10-22, domínio pronto.** `ImportacaoDeGrade` (em `grade/lib/src/importacao_de_grade.dart`) lê a planilha como texto, monta a prévia (turmas e salas encontradas) e publica pela porta `RepositorioGrade.substituir`. Importar não toca na grade publicada. Testado com linhas brutas em memória. Faltam: leitor de .xlsx com teste de fumaça, tela do painel (depende do 05) e o teste de tudo ou nada no banco (depende do 10).
