# 13: Corrigir os achados da revisão da versão 1.0

**O que entrega:** a publicação pelo GitHub fica segura com dois admins ao mesmo tempo, o site funciona com domínio próprio e o domínio volta a ter dependências limpas.
**Bloqueado por:** Nada
**Status:** ready-for-agent

Revisão em dois eixos (padrões e spec) de `a57aceb..077f5d7`, feita em 2026-10-22. Ordem sugerida: um commit por grupo.

## 1. Concorrência e erros do GitHub

- [ ] A versão do arquivo (sha) viaja com a grade lida: publicar grava por cima da versão que a prévia leu, e não da última leitura qualquer. Hoje `RepositorioGradeNoGitHub._versao` muda a cada `gradeAtual()` (prévia, diferenças, listar turmas), e uma publicação pode apagar a de outro admin sem dar 409.
- [ ] Editar ou excluir uma aula que mudou no GitHub desde a leitura avisa o conflito, em vez de duplicar a aula (`EdicaoDeAulas.salvar`, `_sem` não acha a original) ou fazer um commit vazio (`excluir`).
- [ ] 403 de limite de requisições não vira "sem permissão"; 422 que não seja de versão não vira "a grade mudou"; o status de `/user` é conferido no login.
- [ ] O login deixa claro que confere a permissão da conta: um token sem "Contents: Read and write" só falha ao publicar (o GitHub não expõe as permissões do token fino).

## 2. Publicação mais robusta

- [ ] Com domínio próprio (ou repositório `dono.github.io`), o site sai na raiz: o `--base-href` do workflow não pode ser fixo em `/<repositório>/`.
- [ ] O painel confere a grade com `conferirGrade` antes de gravar, como o Action. Hoje o Action barra o deploy, mas o commit inválido já está na `main`: painel e consulta passam a divergir, e todo push seguinte falha até alguém reverter.
- [ ] O Action não roda para commits só de documentos (`docs/**`, `*.md`, `.scratch/**`).
- [ ] A ADR 0001 deixa de citar `SherlockH4mst3r/horario-fatecrp` (decisão: nenhuma conta fixa).
- [ ] Registrar a remoção do service worker (ADR ou comentário na ADR 0001).

## 3. Arquitetura e mensagens

- [ ] Quebrar o ciclo `importacao_de_grade.dart` ↔ `edicao_de_aulas.dart`: `AulaDigitada` e `colunasDaPlanilha` vão para um módulo próprio.
- [ ] `conferirGrade` valida a `Grade` sem criar `RepositorioGradeEmMemoria` (o domínio não depende de adaptador concreto).
- [ ] O "aula N" das mensagens bate com a posição no `grade.json` (hoje `conferirGrade` ordena antes; `EdicaoDeAulas` não). Uma função só monta esse texto.
- [ ] `EdicaoDeAulas.salvar` não relê a grade depois de publicar só para devolver a aula salva.
- [ ] As mensagens de publicação dizem a mesma coisa sobre o tempo: `importacao_da_planilha.dart` ainda diz "já mostra a nova grade ao recarregar"; o certo é "em até alguns minutos".
