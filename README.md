# Grade de aulas – Fatec

Site onde o aluno escolhe curso e semestre e vê em que sala, andar e horário são as suas aulas, no computador ou no celular. A secretaria publica a grade por uma planilha do Excel, num painel com login.

**Por que assim:** é gratuito, não sai do ar por inatividade e guarda o histórico de todas as grades publicadas. Tudo roda no GitHub: o site no GitHub Pages, a grade num arquivo do repositório e o login pela conta do GitHub. A decisão está em [docs/adr/0001-publicar-pelo-github.md](docs/adr/0001-publicar-pelo-github.md).

## Como funciona

```
Admin no painel (/#/admin) ── importa a planilha, confere a prévia, publica
        │  grava app/web/dados/grade.json no repositório (um commit)
        ▼
GitHub Action ── testa, confere a grade e publica o site; grade com erro não sai
        │  em alguns minutos
        ▼
Aluno abre o site e vê a grade nova
```

## Adotar o site (para a faculdade, ou quem for cuidar dele)

1. **Copie o repositório** para uma organização da faculdade no GitHub. Dá para usar *Fork* ou pedir ao dono atual que transfira o repositório em *Settings › General › Transfer*. Uma organização (gratuita) é melhor que uma conta pessoal: vários admins, e o projeto não depende de uma pessoa.
2. **Ligue o Pages:** em *Settings › Pages › Build and deployment › Source*, escolha **GitHub Actions**.
3. **Ligue os Actions**, se for um fork: na aba *Actions*, aceite habilitar os workflows.
4. **Publique pela primeira vez:** na aba *Actions*, abra "Publicar o site" e clique em *Run workflow*. Também vale qualquer push na `main`.
5. O site fica em `https://<organização>.github.io/<repositório>/`, e o painel, em `.../#/admin`. O nome do repositório não está fixo no código: o site usa o repositório de onde é publicado.

Para um endereço próprio, configure um domínio em *Settings › Pages › Custom domain* e um registro CNAME no DNS. Um subdomínio da faculdade depende de quem administra o DNS dela.

## Incluir admins

Admin é quem pode escrever no repositório. O GitHub recusa a gravação de quem não pode, mesmo que alguém contorne o painel.

1. Na organização, convide a pessoa em *People › Invite member* e dê a ela acesso **Write** ao repositório. Pode ser por um time "admins".
2. A pessoa gera um **token fino** (fine-grained), uma vez por semestre, em <https://github.com/settings/personal-access-tokens/new>:
   - **Resource owner:** a organização.
   - **Repository access:** *Only select repositories* › o repositório do site.
   - **Permissions:** *Contents* › **Read and write**.
   - **Expiration:** o fim do semestre.
3. A pessoa cola o token no painel. Ele fica só naquela aba do navegador e some quando ela fecha.

Se a organização exigir aprovação de tokens, aprove-os em *Settings › Personal access tokens*, na organização. Num repositório de conta pessoal, um colaborador não consegue gerar token fino para ele; só um token *classic* com o escopo `public_repo`, que vale para todos os repositórios públicos da pessoa. Por isso, a organização.

## Publicar e corrigir a grade

- **Planilha:** uma linha por aula, com as colunas Curso, Turno, Semestre, Dia, Início, Fim, Disciplina, Professor, Sala e Andar, em qualquer ordem. Sala que alterna entre duas salas se escreve "L1/S2", com o andar de cada uma ("1º andar/3º andar"). Sala ainda sem lugar se escreve "A definir – ..." e pode ficar sem andar.
- **Mudar a grade atual:** no painel, use *Baixar a grade publicada*, edite no Excel e importe de volta. A prévia mostra só o que mudou.
- **Corrigir uma aula:** use *Corrigir aulas*, sem planilha.
- **O sistema barra:** campo vazio, horário inválido, dia fora de segunda a sábado, duas aulas na mesma sala ou na mesma turma ao mesmo tempo, e a mesma sala em andares diferentes. **Avisa, sem barrar:** o mesmo professor em duas aulas ao mesmo tempo.
- **Desfazer:** cada publicação é um commit em `app/web/dados/grade.json`. Para voltar a uma grade anterior, reverta o commit no GitHub (*History* do arquivo).

## Desenvolver

- `grade/`: o domínio, em Dart puro (consulta, importação, correção e conferência da grade). `dart test`.
- `app/`: o site, em Flutter Web. `flutter test`.
- `app/web/dados/grade.json`: a grade publicada.
- `.github/workflows/publicar-site.yml`: testes, conferência da grade (`grade/bin/conferir_grade.dart`) e publicação.

Para rodar na máquina com o painel, passe o repositório. Sem ele, o site fica só com a consulta:

```
cd app
flutter run -d chrome --dart-define=GITHUB_REPO=<organização>/<repositório>
```

O painel, rodando na máquina, grava no repositório de verdade.
