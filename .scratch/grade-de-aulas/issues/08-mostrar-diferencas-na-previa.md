# 08: Mostrar diferenças na prévia

**O que entrega:** antes de publicar, o admin vê o que a planilha muda em relação à grade atual.
**Bloqueado por:** 06
**Status:** ready-for-agent

- [x] A prévia lista as aulas novas, as removidas e as alteradas.
- [x] Aula alterada mostra o valor antigo e o novo de cada campo que mudou (ex.: sala B12 → B14).
- [x] Uma aula é a mesma quando coincidem turma, disciplina e dia; a mudança de sala, horário ou professor conta como alteração.
- [x] Sem grade publicada, todas as aulas aparecem como novas.
- [x] Planilha idêntica à grade atual mostra "Nenhuma mudança".

## Comments

**2026-10-22, pronto.** `Diferencas.entre` (em `grade/lib/src/diferencas.dart`) compara aula por aula; `importar` passa a ser assíncrono, porque lê a grade publicada. Quando a mesma disciplina aparece mais de uma vez no dia da turma (ex.: PROG WEB do ADS Manhã 5º, quinta às 07:40 e às 11:20), as aulas são emparelhadas pela ordem de início. Com erro na planilha, a prévia não mostra diferenças: as linhas com erro pareceriam aulas removidas.
