# 11: Mostrar o andar da sala

**O que entrega:** cada aula mostra, junto da sala, o andar onde ela fica (Térreo, 1º, 2º ou 3º andar), para o aluno achar a sala no prédio.
**Bloqueado por:** 01
**Status:** ready-for-agent

- [x] O domínio `grade` tem o andar como valor fechado: Térreo, 1º, 2º e 3º andar.
- [x] Toda aula tem um andar; a grade semeada traz andares variados.
- [x] Cada aula mostra a sala e o andar (ex.: "Sala B12 · 1º andar").
- [x] Testes do domínio e de widget cobrem o andar.

O andar vem de uma coluna nova na planilha. A leitura e a validação dessa coluna ficam nos tickets 06 e 07; a coluna no banco, no 10.

## Comments

**2026-10-22, salas duplas.** A aula agora guarda um andar por sala. A tela mostra "Sala S4/L3 · 1º andar/3º andar", um andar só quando as salas ficam no mesmo, e nenhum na sala a definir.
