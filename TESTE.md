# Roteiro de teste: skills do Matt Pocock

**Objetivo: validar as 5 skills do vídeo e a ponte com as nossas (brevidade, Código Limpo, Arquitetura Limpa).**

**Por que importa:** se as saídas não seguirem nossos formatos, ajustamos as regras antes de usar em projeto real.

Abra o Claude Code nesta pasta (`claude`). Marque cada item ao conferir.

## 0. Setup
`/mattpocock-skills:setup-matt-pocock-skills`
- Tracker: **local markdown**. Labels: **sim** (padrão). Arquivo: **CLAUDE.md**.
- [ ] Criou `docs/agents/` e a seção `## Agent skills` no `CLAUDE.md`.

## 1. Entrevista
`/grill-me Quero um app web simples de agendamento para uma clínica pequena`
- [ ] Perguntas em rodadas, numeradas, cada uma com recomendação ➡️.
- [ ] "Sim" aceita a recomendação.
- [ ] **Brevidade:** título ≤ 6 palavras, pergunta em 1 frase.
- [ ] Só encerra quando você confirma o entendimento.

Dica: responda com algumas recusas ("isso não entra agora") para testar o `Out of Scope` no passo 2.

## 2. Documento do combinado
`/to-spec`
- [ ] Propõe as seams de teste e pede confirmação.
- [ ] Spec sem caminhos de arquivo nem código.
- [ ] **Brevidade:** lide, "Por que importa" e "Decisões-chave" no topo.
- [ ] `Out of Scope` traz as suas recusas, com o porquê.

## 3. Divisão em partes
`/to-tickets`
- [ ] Fatias verticais (tela + lógica + dados), não por camada.
- [ ] Cada ticket diz por quem é bloqueado; pede aprovação.
- [ ] Gera `.scratch/<feature>/issues/01-....md`, um arquivo por ticket.
- [ ] **Brevidade:** título com verbo, "O que entrega" em 1 frase, critérios verificáveis.

## 4. Construção com critério
`git switch -c feat/agendamento` e depois `/implement 01`
- [ ] Teste escrito antes do código (vermelho → verde).
- [ ] Roda typecheck e testes; chama o code-review no fim; faz commit.
- [ ] **Código Limpo:** testes F.I.R.S.T., nomes do `GLOSSARY.md`.

## 5. Conferida de fora
`/mattpocock-skills:code-review main`
- [ ] Usou o `CODING_STANDARDS.md` e os checklists dos livros.
- [ ] `## Standards` e `## Spec` separados, sem reordenar entre eixos.
- [ ] **Brevidade:** lide por eixo; achados rotulados **violação** ou **julgamento**.

## Bônus
- `/wait-what` após uma resposta confusa: deve re-explicar em português, curto.
- `/handoff` ao fim: formato "Onde paramos / Próximo passo".

## Anote aqui o que falhou
- 
