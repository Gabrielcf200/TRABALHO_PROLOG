# Etapa 07 — Interface desktop

> **Concluída em 2026-11-19.** Janela conferida por print e por 4 testes de fumaça (com uma resposta falsa no lugar da LLM). Falta testar com a chave real do Gemini.

**Objetivo:** o chat do esboço do Gabriel, com barra lateral (dia e ramais ativos) e histórico de rotas.

**Depende de:** [etapa 06](06-llm.md).
**Spec:** [spec/app-desktop.md](../spec/app-desktop.md), seção "Interface".

## Entregáveis

- `app/main.py` (classe `App`).
- `app/testes/test_interface.py`.

## Critérios de aceite

- Os ramais mostram Japeri como "Expresso" em dia útil e "Parador" no sábado.
- Enviar mostra a pergunta e a bolha de espera, desativa o botão e depois troca a espera pela resposta.
- Texto vazio não envia. "Limpar Conversa" volta à mensagem de boas-vindas.
- A janela não congela enquanto a LLM responde.

## Fora desta etapa

O `.exe` fica na [etapa 08](08-executavel.md).
