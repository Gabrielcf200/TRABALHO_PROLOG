# Etapa 00 — Ambiente

**Objetivo:** ter o SWI-Prolog rodando e o esqueleto de arquivos carregando sem erro.

**Depende de:** nada.

## Entregáveis

> **Concluída em 2026-11-19.** SWI-Prolog 11.0.0 instalado, esqueleto carregando sem warning, teste de esqueleto passando, repositório git iniciado.

- SWI-Prolog 9 ou mais novo instalado: `winget install SWI-Prolog.SWI-Prolog` (ou o instalador do site swi-prolog.org).
- Pasta `src/` com `estacoes.pl`, `operacao.pl`, `roteador.pl` e `main.pl`. Cada um é um `module/2` vazio, e o `main.pl` carrega os três.
- Pasta `testes/` com um `testes.pl` vazio usando `plunit`.
- `git init` na pasta do projeto (opcional, mas recomendado).

## Critérios de aceite

- `swipl src/main.pl` abre sem nenhum warning.
- `swipl -g run_tests -t halt testes/testes.pl` roda e termina com código 0.

## Fora desta etapa

Qualquer fato ou regra da SuperVia.
