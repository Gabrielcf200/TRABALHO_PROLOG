# App desktop (Python + LLM)

Um chat no computador: o usuário escreve em português, e o app responde com a rota de trem. O núcleo Prolog ([contrato-python.md](contrato-python.md)) não muda.

## Fluxo

```
texto do usuário
  → LLM "interpretar"   → JSON de pedido             (app/llm.py)
  → Python valida       → pedido seguro              (app/llm.py)
  → swipl src/api.pl    → JSON da resposta do Prolog (app/prolog.py)
  → LLM "responder"     → texto em português         (app/llm.py)
  → bolha no chat                                     (app/main.py)
```

Quem liga as partes é o `app/pipeline.py`. Enquanto o pipeline roda, o chat mostra a bolha provisória "Hmm, deixa eu ver…", que depois é trocada pela resposta.

## Ponte JSON: `src/api.pl`

O Python roda `swipl src/api.pl`, manda **um** JSON no stdin e lê **um** JSON no stdout. O Python nunca monta código Prolog: os textos viram átomos dentro do `api.pl`, então um nome malicioso vindo da LLM só vira um local desconhecido.

**Pedidos**

| `acao` | Campos | Chama |
|--------|--------|-------|
| `rota` | `origem`, `destino`, `dia`, `hora: [H, M]` | `rota/5` |
| `info_ramal` | `ramal`, `dia` | `info_ramal/3` |
| `ramais_do_dia` | `dia` | `info_ramal/3` dos 5 ramais principais → `ok(ramais([info(...), ...]))` |
| `resolver_local` | `local` | `resolver_local/2` |

**Resposta:** o mesmo termo do contrato, convertido de forma genérica:

| Prolog | JSON |
|--------|------|
| átomo | string |
| número | número |
| lista | array |
| `f(X)` | `{"f": X}` |
| `f(X, Y, …)` | `{"f": [X, Y, …]}` |

Exemplo: `ok(estacao(maracana))` vira `{"ok": {"estacao": "maracana"}}`.

Problemas na entrada (JSON inválido, campo faltando) viram `{"erro": {"interno": "..."}}`. Ação desconhecida vira `{"erro": {"acao_desconhecida": "..."}}`.

Cada consulta abre um `swipl` novo, por volta de 0,3 s. O BOM que o PowerShell coloca no começo do texto é descartado.

## Onde o swipl é procurado

Nesta ordem: a variável `SWIPL` no `.env`, o `swipl` do PATH e `C:\Program Files\swipl\bin\swipl.exe`.
