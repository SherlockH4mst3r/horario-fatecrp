# 1. Site no GitHub Pages, grade no repositório e login por token do GitHub

**Status:** aceita (2026-10-22). Substitui o plano da spec de usar Cloudflare Pages e Supabase (tickets 02 e 10).

## Contexto

A spec previa Supabase (Postgres, login e RLS) e Cloudflare Pages. O plano gratuito do Supabase pausa o projeto depois de 7 dias com pouca atividade, e a grade muda poucas vezes por semestre: o site ficaria pausado a maior parte do tempo, com risco de perder o projeto depois de 90 dias. O admin também não quer depender de uma plataforma de terceiros para o banco.

## Decisão

- **Hospedagem:** o site (build do Flutter Web) fica no GitHub Pages do repositório `SherlockH4mst3r/horario-fatecrp`, publicado por um GitHub Action a cada push na `main`.
- **Grade:** é o arquivo `app/web/dados/grade.json` no repositório, no formato de `gradeComoJson`. A consulta pública lê o `dados/grade.json` publicado junto com o site, sem login.
- **Publicar:** o painel grava o arquivo pela API do GitHub (um commit por publicação ou correção). O Action roda `bin/conferir_grade.dart`, com as mesmas regras da importação, e não publica uma grade com erro.
- **Login do admin:** um token fino do GitHub (fine-grained), só deste repositório e só com "Contents: Read and write". O painel confere o token na API e guarda-o no `sessionStorage` da aba. O site não guarda senha nenhuma: admin é quem pode escrever no repositório, e o GitHub recusa gravações sem permissão.

## Consequências

- Gratuito, sem pausa, e com o histórico de todas as grades (quem mudou e quando; desfazer é reverter um commit).
- No plano gratuito do GitHub, o repositório é público: o código e o histórico da grade ficam visíveis, como a própria grade no site.
- Uma publicação aparece na consulta em alguns minutos (o tempo do Action e do cache do Pages), não na hora.
- As regras que o banco garantiria (conflito de sala, grade válida) passam a ser garantidas pelo Action. A troca tudo ou nada vem do próprio commit.
- Se o token incomodar, o próximo passo é "Entrar com GitHub" (OAuth), que precisa de um serviço pequeno, como um Cloudflare Worker, para trocar o código pelo token.
