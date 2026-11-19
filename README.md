# SuperVia-Prolog

Rotas de trem da SuperVia (Rio de Janeiro), no estilo do Moovit. O núcleo de regras é em SWI-Prolog. Por cima dele há um app desktop em Python: o usuário escreve em português, uma LLM (Gemini) entende o pedido, o Prolog calcula a rota e a LLM explica a resposta.

**Tecnologias:** SWI-Prolog 11 (funciona a partir do 9) e plunit; Python 3.13, CustomTkinter, `openai` (apontando para o Gemini) e python-dotenv.

## Pasta

| Arquivo | O que tem |
|---------|-----------|
| [pedido-original.md](pedido-original.md) | o pedido do Gabriel, sem alterações |
| [spec/dados.md](spec/dados.md) | ramais, extensões, estações, integrações, bairros |
| [spec/operacao.md](spec/operacao.md) | calendário, horários, intervalos, expresso × parador |
| [spec/roteador.md](spec/roteador.md) | busca de rota, sentido, baldeação, `info_ramal/3` |
| [spec/contrato-python.md](spec/contrato-python.md) | formato exato das respostas do Prolog |
| [spec/app-desktop.md](spec/app-desktop.md) | ponte JSON, LLM, pipeline e interface |
| [etapas/](etapas/) | etapas 00 a 08, em ordem (cada uma depende da anterior) |

## Como rodar

1. Instalar o SWI-Prolog e as dependências do Python:

```bash
winget install SWI-Prolog.SWI-Prolog
```
```bash
python -m pip install -r app/requirements.txt
```

2. Copiar `app/.env.example` para `app/.env` e colar a chave gratuita do Gemini em `LLM_API_KEY`. A chave é criada em aistudio.google.com/apikey.

3. Abrir o app:

```bash
python app/main.py
```

**Executável (.exe):** `powershell -ExecutionPolicy Bypass -File app\gerar_exe.ps1` gera `dist\SuperViaIA\SuperViaIA.exe`. Ele precisa do SWI-Prolog instalado e de um `.env` ao lado do `.exe` ([etapa 08](etapas/08-executavel.md)).

**Só o Prolog, sem o app:**

```bash
swipl src/main.pl
```

**Testes:**

```bash
swipl -g run_tests -t halt testes/testes.pl
```
```bash
python -m unittest discover app/testes
```

Se o terminal não achar o `swipl`, use o caminho completo: `& "C:\Program Files\swipl\bin\swipl.exe"`.

## Estado

Etapas 00 a 08 concluídas. O app e o `.exe` funcionam de ponta a ponta nos testes com uma LLM falsa. **Falta testar com a chave real do Gemini.**

Pendências conhecidas:
- conferir estações e horários na fonte oficial da TrensRJ (o que falta está marcado em [spec/dados.md](spec/dados.md) e [spec/operacao.md](spec/operacao.md));
- fora do escopo por enquanto: tempo de viagem, horário do próximo trem, baldeação a pé, metrô e BRT.

Desde 30/05/2026 a operadora dos trens é a TrensRJ, não mais a SuperVia (detalhes em [spec/dados.md](spec/dados.md)).
