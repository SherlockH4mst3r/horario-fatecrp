"""Gera a planilha de exemplo do teste de fumaça do leitor de .xlsx, como o Excel a salvaria.

Uso (com openpyxl instalado): python gerar_grade_exemplo.py grade_exemplo.xlsx
"""
import sys
from datetime import time

from openpyxl import Workbook

livro = Workbook()
folha = livro.active
folha.title = "Grade 2027-1"
folha.append(["Curso", "Turno", "Semestre", "Dia", "Início", "Fim", "Disciplina", "Professor", "Sala", "Andar", "Observação"])
linhas = [
    ["ADS", "Noite", 1, "Segunda", time(19, 0), time(20, 40), "Algoritmos", "Ana Souza", "B12", "1º andar", None],
    ["ADS", "Noite", 1, "Segunda", time(20, 50), time(22, 30), "Matemática Discreta", "Carlos Lima", "B12", "1º andar", "troca em abril"],
    [None] * 11,
    ["ADS", "Noite", 3, "Quarta", time(19, 0), time(22, 30), "Banco de Dados", "Rita Alves", "Lab 1", "2º andar", None],
    ["Gestão Empresarial", "Manhã", 2, "Terça", "7:40", time(9, 20), "Contabilidade", "José Prado", 101, "Térreo", None],
]
for linha in linhas:
    folha.append(linha)
for coluna in ("E", "F"):
    for celula in folha[coluna][1:]:
        if isinstance(celula.value, time):
            celula.number_format = "hh:mm"
livro.save(sys.argv[1])
