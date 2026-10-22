Status: ready-for-agent

# Grade de aulas FATEC RP

O aluno escolhe curso e semestre e vê, no computador ou no celular, em que sala e horário são suas aulas.

**Por que importa:** hoje o aluno depende de PDF, mural ou grupo de mensagem para achar a sala. Uma consulta pública e sempre atualizada acaba com a dúvida no corredor.

**Decisões-chave:**
- Consulta pública, sem login. Só o admin escreve.
- A grade entra por planilha .xlsx, com prévia, e a importação substitui o semestre letivo inteiro.
- Flutter Web no Cloudflare Pages, com Supabase (Postgres) por trás.
- O banco repete as regras críticas: troca atômica, conflito de sala barrado e RLS.
- Atende só a FATEC Ribeirão Preto e só o semestre letivo vigente.

## Problem Statement

O aluno não tem um lugar único e confiável para saber em que sala e horário é cada aula da sua turma. A informação circula em arquivos e mensagens que ficam desatualizados e são difíceis de ler no celular.

A secretaria, por sua vez, não tem um jeito simples de publicar a grade e corrigir uma sala sem refazer tudo.

## Solution

Um site responsivo onde o aluno escolhe curso (com turno) e semestre e vê a grade da semana da sua turma. No computador ela aparece em tabela; no celular, como lista por dia que abre no dia de hoje. O site lembra a última escolha.

O admin entra num painel com login. Lá ele importa a planilha do semestre letivo, revisa a prévia (erros, diferenças, turmas e salas encontradas) e publica. Depois, corrige aulas avulsas sem reimportar.

## User Stories

### Aluno: consulta
1. Como aluno, quero abrir o site sem criar conta, para consultar a grade na hora.
2. Como aluno, quero escolher meu curso numa lista, para chegar à minha turma.
3. Como aluno, quero que o turno faça parte da opção do curso (ex.: "ADS – Noite"), para não confundir com a turma de outro turno.
4. Como aluno, quero escolher meu semestre (1º a 6º), para ver só as aulas da minha turma.
5. Como aluno, quero ver a grade da semana da minha turma, para planejar meus dias.
6. Como aluno, quero ver em cada aula a disciplina, o professor, a sala, o andar, o início e o fim, para saber aonde ir e confirmar que é a turma certa.
7. Como aluno, quero ver as aulas de cada dia em ordem de horário, para ler a sequência do dia.
8. Como aluno, quero ver de qual semestre letivo é a grade (ex.: "Grade 2026/2"), para ter certeza de que ela está atual.
9. Como aluno, quero que o site lembre meu último curso e semestre, para abrir direto na minha grade.
10. Como aluno, quero poder trocar de curso e semestre a qualquer momento, para consultar outra turma.

### Aluno: telas
11. Como aluno no computador, quero a grade como tabela de dias × horários, para ver a semana inteira de uma vez.
12. Como aluno no celular, quero a grade como lista por dia, para ler sem rolar para o lado.
13. Como aluno no celular, quero que a lista abra no dia de hoje, para ver logo as aulas de agora.
14. Como aluno, quero ver as aulas de sábado quando houver, para não perder aula no fim de semana.
15. Como aluno, quero ler "Sem aulas hoje" num dia sem aula, com os outros dias logo abaixo, para não achar que o site quebrou.
16. Como aluno, quero ler "Grade ainda não publicada" antes da primeira importação, para saber que o problema não é a minha escolha.
17. Como aluno, quero que uma turma sem aulas mostre uma mensagem clara, para não ficar diante de uma tela em branco.

### Admin: acesso
18. Como admin, quero entrar no painel por `/admin` com e-mail e senha, para que só a faculdade altere a grade.
19. Como admin, quero que ninguém consiga criar conta sozinho, para que o acesso fique restrito.
20. Como admin, quero sair do painel, para não deixar a sessão aberta num computador compartilhado.
21. Como visitante sem login, não quero conseguir alterar a grade nem pela tela nem direto no banco, para que a grade publicada seja confiável.

### Admin: importação
22. Como admin, quero enviar a planilha .xlsx direto, sem converter para CSV, para não ter passo extra.
23. Como admin, quero informar o semestre letivo na importação, para que a planilha não repita esse dado em toda linha.
24. Como admin, quero uma linha por aula com curso, turno, semestre, dia, início, fim, disciplina, professor, sala e andar, para montar a planilha num formato simples.
25. Como admin, quero ver uma prévia antes de publicar, para não apagar a grade por engano.
26. Como admin, quero que a prévia aponte cada erro pela linha da planilha, para corrigir rápido no Excel.
27. Como admin, quero que campo vazio bloqueie a importação, para não publicar aula incompleta.
28. Como admin, quero que horário inválido (formato errado, ou fim antes do início) bloqueie a importação, para não publicar aula impossível.
29. Como admin, quero que dia fora de segunda a sábado bloqueie a importação, para pegar erro de digitação.
30. Como admin, quero que duas aulas na mesma sala, no mesmo dia e em horários sobrepostos bloqueiem a importação, para não mandar duas turmas ao mesmo lugar.
31. Como admin, quero ver na prévia as turmas e as salas encontradas, para notar nomes digitados de dois jeitos ("ADS" × "Análise e Desenv.").
32. Como admin, quero ver na prévia o que muda em relação à grade atual (aulas novas, removidas e alteradas), para conferir o impacto.
33. Como admin, quero confirmar a publicação só quando a prévia não tem erros, para nunca publicar grade inválida.
34. Como admin, quero que a importação substitua a grade inteira, para não ter que mesclar com a anterior.
35. Como admin, quero que a substituição seja tudo ou nada, para que uma falha no meio não deixe a grade pela metade.
36. Como admin, quero desistir na prévia sem alterar nada, para poder corrigir a planilha antes.

### Admin: correções
37. Como admin, quero criar uma aula avulsa, para incluir o que faltou sem reimportar.
38. Como admin, quero editar uma aula (sala, horário, professor etc.), para corrigir um dado na hora.
39. Como admin, quero excluir uma aula, para tirar o que entrou por engano.
40. Como admin, quero que a aula avulsa passe pela mesma validação da importação, para que a correção não crie conflito de sala.
41. Como admin, quero ver a correção publicada na hora para os alunos, para que eles não sigam a informação antiga.

## Implementation Decisions

### Módulos
- **Domínio `grade` (Dart puro).** Módulo profundo com interface pequena. Não depende de Flutter nem de Supabase. Concentra toda a regra:
  - `importar(planilha, semestreLetivo)`: lê as linhas, valida e devolve a **prévia** (erros por linha, diferenças contra a grade atual, turmas e salas encontradas). A confirmação publica a prévia sem erros.
  - `gradeDaTurma(turma)`: devolve as aulas agrupadas por dia e ordenadas por início, já com os estados vazios (grade não publicada, turma sem aulas, dia sem aulas).
  - Operações de aula avulsa (criar, editar, excluir), com a mesma validação da importação.
  - Lista de turmas disponíveis para o seletor.
- **Repositório da grade (porta).** O domínio a define. A implementação Supabase fica na borda. Nos testes, um repositório em memória a substitui.
- **Leitor de .xlsx (adaptador).** Converte o arquivo em linhas brutas de texto. Não valida nada; isso cabe ao domínio.
- **App Flutter Web.** Só a casca: a tela pública de consulta e o painel `/admin`. Renderiza o que o domínio entrega e não decide nada.
- **Banco Supabase.** Tabelas, função de substituição, constraint e RLS.

### Dados
- Tabela de aulas com curso, turno e sala em texto (sem tabelas de cadastro), semestre, dia da semana (segunda a sábado), início, fim, disciplina, professor, andar (térreo a 3º) e semestre letivo.
- Turma = curso + turno + semestre. É derivada das aulas, não é tabela.
- Só uma grade (a do semestre letivo vigente) existe por vez. Não há histórico.

### Regras no banco
- **Substituição atômica:** uma função SQL (RPC) apaga a grade e insere a nova numa transação só.
- **Conflito de sala:** uma *exclusion constraint* impede duas aulas na mesma sala, no mesmo dia, com intervalos de horário sobrepostos. Ela vale para importação e para edição avulsa.
- **RLS:** visitante anônimo só lê. Admin autenticado lê e escreve.

### Acesso
- Supabase Auth com e-mail e senha, com auto-cadastro desligado. Os admins são criados no painel do Supabase.
- O painel fica numa rota `/admin` do mesmo app.

### Cliente
- O último curso e semestre ficam guardados no navegador (armazenamento local). Se o armazenamento falhar, o site abre no seletor.
- O layout troca de tabela semanal para lista por dia conforme a largura da tela. No celular, a lista abre no dia de hoje.

### Entrega
- Build Flutter Web publicado no Cloudflare Pages, com deploy pelo Git.
- As chaves públicas do Supabase (URL e anon key) vão no build. A service key nunca vai ao cliente.

## Testing Decisions

- **Bom teste:** verifica o comportamento pela interface pública do módulo, não pela implementação. Segue F.I.R.S.T. e usa os termos do `GLOSSARY.md` nos nomes.
- **Seam 1: domínio `grade`.** Testes unitários em Dart puro, com repositório em memória. Cobrem toda a validação (campo vazio, horário inválido, dia fora da faixa, conflito de sala), a prévia (erros por linha, diferenças, turmas e salas encontradas), a substituição, as aulas avulsas, o agrupamento e a ordenação por dia, o dia de hoje e os estados vazios.
- **Seam 2: banco Supabase local (`supabase start`).** Testes de integração só para o que o banco garante sozinho: a substituição é tudo ou nada, a constraint barra conflito de sala tanto na importação quanto na edição avulsa, e a RLS deixa o anônimo só ler e o admin escrever.
- **Fora:** testes de widget Flutter e do leitor de .xlsx além de um caso de fumaça. A casca não decide nada.
- **Prior art:** nenhum. O repo ainda não tem código; estes testes inauguram o padrão.

## Out of Scope

- **Atalho "agora / próxima aula":** a entrada fica só por curso + semestre, para manter a tela simples.
- **Mudança pontual por data (troca de sala de um dia, aula cancelada, avisos):** exige calendário e dobra o escopo. É o primeiro candidato da próxima versão.
- **Apps Android e iOS:** o site responsivo basta por agora. O mesmo código Flutter vira app depois.
- **Outras unidades FATEC:** complicam cadastro e permissões sem ganho agora.
- **Histórico de semestres letivos anteriores:** não serve ao aluno.
- **Cadastro de cursos e salas:** a prévia cobre o erro de digitação.
- **Integração com o SIGA:** não tem API pública.
- **Login de aluno e gestão de admins pelo site:** a consulta é informacional, e os admins são criados no Supabase.
- **Importação em CSV:** a secretaria usa Excel.

## Further Notes

- **Custo do Flutter Web:** o primeiro carregamento no celular gira em torno de 2 MB. Aceito em troca de um código só, que vira app depois.
- **Risco do texto livre:** "ADS" e "Análise e Desenv." viram duas turmas se o admin não notar na prévia. Se isso se repetir, o próximo passo é cadastrar cursos e salas.
- **Glossário:** os termos estão em `GLOSSARY.md` (semestre letivo × semestre, turma, aula, grade, importação, prévia).
