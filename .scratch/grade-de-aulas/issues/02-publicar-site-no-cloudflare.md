# 02: Publicar o site no Cloudflare

**O que entrega:** o site do ticket 01 abre por uma URL pública, ligado ao Supabase de produção, com deploy a cada push na `main`.
**Bloqueado por:** 01, 10
**Status:** wontfix

- [ ] O projeto Supabase de produção tem a migração e o seed aplicados.
- [ ] Um push na `main` gera o build Flutter Web e publica no Cloudflare Pages.
- [ ] A URL pública mostra a grade semeada no celular e no computador.
- [ ] Só a URL e a anon key do Supabase vão no build; a service key não aparece no repo nem no bundle.

**2026-10-22, decisão nova (docs/adr/0001-publicar-pelo-github.md).** O site vai para o GitHub Pages, a grade fica em `app/web/dados/grade.json` no repositório e o admin entra com um token fino do GitHub. Este ticket fica substituído por essa decisão.
