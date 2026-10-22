# 01: Mostrar grade de turma semeada

**O que entrega:** o aluno abre o site, escolhe curso (com turno) e semestre e vê as aulas da turma, vindas de uma grade semeada num repositório em memória (sem Supabase).
**Bloqueado por:** Nada
**Status:** ready-for-agent

- [x] Repositório em memória implementa a porta do domínio, com um seed de ao menos duas turmas do semestre letivo 2026/2.
- [x] Domínio `grade`, em Dart puro, expõe os cursos oferecidos (curso + turno, semestres de 1º a 6º) e `gradeDaTurma(turma)`, com as aulas agrupadas por dia e ordenadas por início (testes com repositório em memória).
- [x] O seletor mostra o curso com o turno (ex.: "ADS – Noite") e o semestre de 1º a 6º.
- [x] Cada aula mostra disciplina, professor, sala, início e fim.
- [x] O topo mostra "Grade 2026/2".
- [x] Com o repositório vazio, o site mostra "Grade ainda não publicada".
- [x] Turma sem aulas mostra uma mensagem própria, não uma tela em branco.
