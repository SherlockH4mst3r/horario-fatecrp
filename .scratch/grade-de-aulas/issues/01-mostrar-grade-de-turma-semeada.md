# 01: Mostrar grade de turma semeada

**O que entrega:** o aluno abre o site, escolhe curso (com turno) e semestre e vê as aulas da turma, vindas de uma grade semeada num repositório em memória (sem Supabase).
**Bloqueado por:** Nada
**Status:** ready-for-agent

- [ ] Repositório em memória implementa a porta do domínio, com um seed de ao menos duas turmas do semestre letivo 2026/2.
- [ ] Domínio `grade`, em Dart puro, expõe a lista de turmas e `gradeDaTurma(turma)`, com as aulas agrupadas por dia e ordenadas por início (testes com repositório em memória).
- [ ] O seletor mostra o curso com o turno (ex.: "ADS – Noite") e o semestre de 1º a 6º.
- [ ] Cada aula mostra disciplina, professor, sala, início e fim.
- [ ] O topo mostra "Grade 2026/2".
- [ ] Com o repositório vazio, o site mostra "Grade ainda não publicada".
- [ ] Turma sem aulas mostra uma mensagem própria, não uma tela em branco.
