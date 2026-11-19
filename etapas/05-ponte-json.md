# Etapa 05 — Ponte JSON Python ↔ Prolog

> **Concluída em 2026-11-19.** `src/api.pl` e `app/prolog.py` prontos, com 10 testes Python passando contra o swipl real.

**Objetivo:** o Python consulta o núcleo Prolog mandando e recebendo JSON, sem nunca montar código Prolog.

**Depende de:** [etapa 04](04-testes-e-exemplos.md).
**Spec:** [spec/app-desktop.md](../spec/app-desktop.md), seção "Ponte JSON".

## Entregáveis

- `src/api.pl` com as ações `rota`, `info_ramal`, `ramais_do_dia` e `resolver_local`, e a conversão genérica termo → JSON.
- `app/prolog.py` com `consultar(pedido) -> dict` e o erro `ErroProlog`.
- `app/testes/test_prolog.py`.
- `.gitignore` deixando `app/.env` fora do git.

## Critérios de aceite

- Piedade → Nilópolis em dia útil faz baldeação em Madureira; no sábado, vai direto.
- Bairro vira estação; local sem trem dá `local_desconhecido`.
- Hora inválida, campo faltando e JSON quebrado viram erro em JSON, sem travar.
- Um "nome" com código Prolog dentro só vira local desconhecido.

## Fora desta etapa

LLM e interface.
