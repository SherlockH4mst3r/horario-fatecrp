# Histórico de versões

## 1.0 – 22/10/2026

Primeira versão no ar, com a grade real do 2º semestre de 2026 (228 aulas, 30 turmas, cursos ADS, GNI, GRH e SBM).

### Consulta pública
- Escolha do curso (com o turno) e do semestre, de 1º a 6º; a última turma fica lembrada no navegador.
- Computador: grade de horários, com cada aula do tamanho da sua duração e uma cor suave por disciplina.
- Celular: lista que começa no dia de hoje ("Sem aulas hoje"; no domingo, começa na segunda).
- Sala e andar em cada aula, inclusive sala dupla ("L1/S2 · 1º andar") e sala a definir.
- Recarregar puxando a tela (celular) ou pelo botão (computador); tema claro (creme) e escuro (jeans).

### Painel do admin (`/#/admin`)
- Login por token fino do GitHub; o site não guarda senha.
- Importação de .xlsx com prévia: erros por linha e coluna, avisos, turmas, salas e o que muda em relação à grade publicada.
- Bloqueio de conflito de sala e de turma, campo vazio, horário, dia, turno, semestre e andar inválidos; aviso (sem bloqueio) de professor em dois lugares.
- Correção de aulas avulsas (criar, editar, excluir) com as mesmas regras.
- Baixar a grade publicada como .xlsx, para editar no Excel e importar de volta.
- Avisos coloridos: verde (sucesso), amarelo (o que o admin resolve), vermelho (falha do sistema).

### Publicação
- Site no GitHub Pages; grade em `app/web/dados/grade.json`; cada publicação é um commit.
- GitHub Action testa, confere a grade e publica; grade com erro não vai ao ar.
- Sem conta fixa no código: outra organização adota o site por fork ou transferência (ver README).

### Pendências
- Achados da revisão da versão 1.0: `.scratch/grade-de-aulas/issues/13-corrigir-achados-da-revisao-1-0.md`.
- Mover o repositório para uma organização do GitHub (facilita incluir admins).

Documentação completa: [docs/Documentacao-Grade-de-Aulas-v1.0.docx](docs/Documentacao-Grade-de-Aulas-v1.0.docx).
