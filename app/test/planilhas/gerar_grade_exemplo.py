"""Gera as planilhas de exemplo dos testes do leitor de .xlsx e do painel, como o Excel as salvaria.

Uso (com openpyxl instalado): python gerar_grade_exemplo.py <pasta de saída>
- grade_exemplo.xlsx: válida, com horas em células de hora, números, coluna de observação, célula de texto vazia
  e linha vazia.
- grade_com_erros.xlsx: um erro de cada tipo que o admin costuma cometer.
"""
import sys
from datetime import time
from pathlib import Path

from openpyxl import Workbook

CABECALHO = ["Curso", "Turno", "Semestre", "Dia", "Início", "Fim", "Disciplina", "Professor", "Sala", "Andar", "Observação"]


def salvar(caminho, linhas):
    livro = Workbook()
    folha = livro.active
    folha.title = "Grade"
    folha.append(CABECALHO)
    for linha in linhas:
        folha.append(linha)
    for coluna in ("E", "F"):
        for celula in folha[coluna][1:]:
            if isinstance(celula.value, time):
                celula.number_format = "hh:mm"
    livro.save(caminho)


pasta = Path(sys.argv[1])
salvar(pasta / "grade_exemplo.xlsx", [
    ["ADS", "Noite", 1, "Segunda", time(19, 0), time(20, 40), "Algoritmos", "Ana Souza", "B12", "1º andar", ""],
    ["ADS", "Noite", 1, "Segunda", time(20, 50), time(22, 30), "Matemática Discreta", "Carlos Lima", "B12", "1º andar", "troca em abril"],
    [None] * 11,
    ["ADS", "Noite", 3, "Quarta", time(19, 0), time(22, 30), "Banco de Dados", "Rita Alves", "Lab 1", "2º andar", None],
    ["Gestão Empresarial", "Manhã", 2, "Terça", "7:40", time(9, 20), "Contabilidade", "José Prado", 101, "Térreo", None],
])
salvar(pasta / "grade_com_erros.xlsx", [
    ["ADS", "Noite", 1, "Segunda", time(19, 0), time(20, 40), "Algoritmos", "Ana Souza", "B12", "1º andar", None],
    ["ADS", "Noite", 1, "Terça", time(19, 0), time(20, 40), "Matemática Discreta", None, "B14", "1º andar", "professor vazio"],
    ["ADS", "Noite", 3, "Domingo", time(19, 0), time(20, 40), "Banco de Dados", "Rita Alves", "Lab 1", "2º andar", "domingo"],
    ["ADS", "Noite", 3, "Quarta", "19h", time(20, 40), "Redes", "Paulo Nunes", "Lab 2", "2º andar", "horário"],
    ["ADS", "Noite", 5, "Segunda", time(20, 0), time(21, 30), "Mobile", "Marta Reis", "B12", "1º andar", "conflito com a linha 2"],
    ["ADS", "Noite", 5, "Terça", time(20, 50), time(22, 30), "Testes", "Paulo Nunes", "B12", "Térreo", "B12 em outro andar"],
])
