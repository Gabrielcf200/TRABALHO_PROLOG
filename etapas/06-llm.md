# Etapa 06 — LLM e pipeline

> **Concluída em 2026-11-19** (com uma LLM falsa nos testes). Falta testar com a chave real do Gemini, que o Gabriel precisa criar e colar em `app/.env`.

**Objetivo:** transformar o texto do usuário num pedido seguro para o Prolog e a resposta do Prolog em português.

**Depende de:** [etapa 05](05-ponte-json.md).
**Spec:** [spec/app-desktop.md](../spec/app-desktop.md), seções "LLM" e "Pipeline".

## Entregáveis

- `app/llm.py`: `interpretar`, `validar`, `normalizar`, `responder`, `ErroLLM` e `--modelos`.
- `app/pipeline.py`: `perguntar` e `ramais_ativos`.
- `app/requirements.txt` e `app/.env.example`.
- A ação `locais` em `src/api.pl`.
- `app/testes/test_llm.py`.

## Critérios de aceite

- `validar` recusa ação e ramal inválidos e nome gigante. Troca dia e hora inválidos pelo padrão e tira os acentos.
- `conversa` e `falta_local` não chamam o Prolog.
- Erro da LLM e falta de chave viram mensagem no chat.
- Com a LLM falsa, o pipeline chega até o Prolog de verdade.
- **Manual, com chave:** "Quero saber como chegar no Méier saindo de Engenho de Dentro" responde com o ramal Deodoro, sentido Central do Brasil, em 1 parada.

## Fora desta etapa

Interface e memória de conversa (o Gabriel decidiu que cada pergunta é interpretada sozinha).
