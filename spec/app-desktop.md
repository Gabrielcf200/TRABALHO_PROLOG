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
| `locais` | — | todos os nomes que `resolver_local/2` entende → `ok(locais(estacoes([...]), apelidos([...]), bairros([...])))` (usado no prompt da LLM) |

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

## LLM: `app/llm.py`

**Provedor:** Google Gemini, no plano gratuito, pelo endpoint compatível com OpenAI (pacote `openai`). Tudo se configura em `app/.env`, criado a partir do `app/.env.example`:

| Variável | Padrão |
|----------|--------|
| `LLM_API_KEY` | — (obrigatória; gratuita em aistudio.google.com/apikey) |
| `LLM_BASE_URL` | `https://generativelanguage.googleapis.com/v1beta/openai/` |
| `LLM_MODEL` | `gemini-3-flash-preview, gemini-flash-lite-latest, gemini-flash-latest` |

`LLM_MODEL` é uma **lista**, testada em ordem. Cada chamada espera no máximo 20 s, sem nova tentativa automática do SDK. Se um modelo der timeout, 5xx, 404 ou bater no limite gratuito (que é por modelo), o app passa para o próximo da lista. Se todos falharem, aparece "modelos muito ocupados". Por que isso existe: em 2026-11-19, o `gemini-flash-latest` ficou sobrecarregado (às vezes 503, às vezes sem resposta), e o app parecia travado, porque o SDK esperava até 10 min por tentativa.

Para ver os modelos que a sua chave enxerga, rode `python app/llm.py --modelos`. Para trocar para Groq, OpenRouter ou Ollama, basta mudar essas três variáveis. No plano gratuito do Gemini, o Google pode usar as mensagens para treinar modelos.

**interpretar(texto, dia, hora) → pedido.** A LLM devolve só JSON, no formato:

```json
{"acao": "rota", "origem": "meier", "destino": "bangu", "dia": "sabado", "hora": [10, 0]}
{"acao": "info_ramal", "ramal": "japeri", "dia": "domingo_feriado"}
{"acao": "conversa"}
```

O prompt leva a lista de nomes da ação `locais`, o dia da barra lateral e a hora do relógio do PC como padrão. Cada pergunta é interpretada sozinha, sem memória da conversa (decisão do Gabriel).

**Validação (fronteira de confiança), em `validar()`:**
- a ação precisa estar na lista;
- dia ou hora inválidos viram o padrão;
- os nomes passam por `normalizar()` (tira acento, minúsculas, `_`) e precisam casar com `^[a-z0-9_]{1,60}$`;
- o ramal precisa ser um dos 8;
- rota sem origem ou sem destino vira `falta_local`, e o app pergunta ao usuário em vez de chamar o Prolog.

Se o JSON vier quebrado, o app tenta de novo uma vez. Se falhar outra vez, mostra "Não entendi a pergunta…".

**responder(pergunta, pedido, resultado) → texto.** A LLM recebe a pergunta, o pedido e o JSON do Prolog, junto com uma explicação de cada campo. Responde em português, com passos numerados e os nomes com acento, sem inventar nada que não esteja no JSON. Para `conversa`, responde em uma ou duas frases e puxa o assunto de volta para os trens.

**Erros** (`ErroLLM`, já com texto para o usuário): falta de chave, chave recusada, modelo inexistente, cota gratuita acabada e sem internet.

## Pipeline: `app/pipeline.py`

- `perguntar(texto, dia, hora=None) -> str` sempre devolve um texto para o chat. Erros da LLM ou do Prolog viram mensagem, nunca exceção.
- `ramais_ativos(dia) -> [("Japeri", "Expresso"), ...]` alimenta a barra lateral.

## Interface: `app/main.py`

CustomTkinter, tema claro ou escuro conforme o Windows. Janela de 1000×660, com mínimo de 820×520.

```
+---------------------+-----------------------------------------------+
| 🚆 SuperVia IA      |  [Histórico de Rotas]  (CTkScrollableFrame)   |
| Dia da Simulação:   |    SuperVia IA: boas-vindas                   |
| [Segunda a Sexta v] |                     Você: pergunta  (direita) |
| Ramais Ativos:      |    SuperVia IA: resposta          (esquerda)  |
| • Deodoro (Parador) |                                               |
| • Japeri (Expresso) |-----------------------------------------------|
| [Limpar Conversa]   |  [ Digite origem/destino…            ] [ > ]  |
+---------------------+-----------------------------------------------+
```

- **Barra lateral (260 px):** o dia escolhido vira o padrão quando a pergunta não fala o dia. "Ramais Ativos" mostra os 5 ramais principais e o modo de cada um naquele dia (`ramais_do_dia`), e atualiza quando o dia muda. "Limpar Conversa" apaga o histórico e volta à mensagem de boas-vindas.
- **Enviar (Enter ou `>`):** aparece a bolha do usuário e a bolha provisória com uma frase sorteada ("Hmm, deixa eu ver…", "Consultando os trilhos…"…). O pipeline roda numa thread, e quando termina o texto da bolha provisória vira a resposta. Enquanto isso o botão fica desativado e um segundo Enter é ignorado.
- **Threads:** as threads de trabalho nunca tocam na janela. Elas põem `(função, args)` numa fila, que a janela esvazia a cada 80 ms. Chamar `after()` de outra thread falha calado quando o `mainloop` não está rodando.
- A hora padrão é a do relógio do PC.

## Executável

O `app/gerar_exe.ps1` gera `dist\SuperViaIA\SuperViaIA.exe` com o PyInstaller. Os `.pl` vão empacotados, mas o `.env` fica **fora**, ao lado do `.exe`, e o SWI-Prolog continua sendo pré-requisito. Detalhes na [etapa 08](../etapas/08-executavel.md).

## Onde o swipl é procurado

Nesta ordem: a variável `SWIPL` no `.env`, o `swipl` do PATH e `C:\Program Files\swipl\bin\swipl.exe`.
