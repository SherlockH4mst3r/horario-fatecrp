# Padrões de código

**Este repo segue Código Limpo e Arquitetura Limpa (Robert C. Martin). Revise contra os checklists abaixo.**

**Por que importa:** um padrão documentado vira critério objetivo de revisão, não gosto pessoal.

## Fontes (leia na revisão)
- Código: `~/.claude/skills/prog-codigo-limpo/references/checklist-revisao.md`
- Cheiros e heurísticas: `~/.claude/skills/prog-codigo-limpo/references/heuristicas-cheiros.md`
- Estrutura e dependências: `~/.claude/skills/prog-arquitetura-limpa/references/checklist-revisao.md`

## Regras que valem como violação (não como opinião)
- Regra da Dependência: núcleo (entidades, use cases) não importa UI, banco, rede ou framework.
- Testes seguem F.I.R.S.T. e testam comportamento externo, não implementação.
- Nomes usam os termos do `GLOSSARY.md`.

## Prioridade dos achados
correção e testes > dependências e limites > duplicação e design > nomes e funções > comentários e formatação.

## Módulos × funções
Ousterhout e Arquitetura Limpa decidem a fronteira e a interface do módulo (interface pequena, muito comportamento atrás). Código Limpo decide o interior (funções pequenas, um nível de abstração). Módulo raso não é defeito de Código Limpo; é defeito de design.

## Exceções deste repo
- Nenhuma por enquanto.
