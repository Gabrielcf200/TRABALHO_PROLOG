"""Conversa com a LLM: texto -> pedido (interpretar) e resultado -> texto (responder).

Configuração no app/.env (modelo em app/.env.example). Spec: spec/app-desktop.md.
Uso extra: python app/llm.py --modelos   (lista os modelos que a sua chave enxerga)
"""
import json
import os
import re
import sys
import unicodedata
from functools import lru_cache
from pathlib import Path

import openai
from dotenv import load_dotenv

import prolog

# No .exe, o .env fica ao lado do executável (a chave nunca vai dentro dele).
PASTA = Path(sys.executable).parent if getattr(sys, "frozen", False) else Path(__file__).parent
load_dotenv(PASTA / ".env")

GEMINI = "https://generativelanguage.googleapis.com/v1beta/openai/"
DIAS = ("segunda_a_sexta", "sabado", "domingo_feriado")
RAMAIS = ("deodoro", "santa_cruz", "japeri", "belford_roxo", "saracuruna",
          "paracambi", "vila_inhomirim", "guapimirim")
NOME = re.compile(r"^[a-z0-9_]{1,60}$")


class ErroLLM(RuntimeError):
    """Falha ao falar com a LLM; a mensagem já é para o usuário ler."""


# ---------------------------------------------------------------- cliente

def _cliente() -> openai.OpenAI:
    chave = os.environ.get("LLM_API_KEY", "").strip()
    if not chave:
        raise ErroLLM("Falta a chave da LLM. Crie o arquivo app/.env a partir do "
                      "app/.env.example e cole sua chave em LLM_API_KEY.")
    return openai.OpenAI(base_url=os.environ.get("LLM_BASE_URL", GEMINI), api_key=chave)


def _modelo() -> str:
    return os.environ.get("LLM_MODEL", "gemini-flash-latest")


def _chat(sistema: str, usuario: str, json_mode: bool = False) -> str:
    extra = {"response_format": {"type": "json_object"}} if json_mode else {}
    try:
        r = _cliente().chat.completions.create(
            model=_modelo(), temperature=0.2,
            messages=[{"role": "system", "content": sistema},
                      {"role": "user", "content": usuario}],
            **extra,
        )
    except openai.AuthenticationError as e:
        raise ErroLLM("A chave da LLM foi recusada. Confira LLM_API_KEY no app/.env.") from e
    except openai.NotFoundError as e:
        raise ErroLLM(f"O modelo '{_modelo()}' não existe para essa chave. Rode "
                      "'python app/llm.py --modelos' e troque LLM_MODEL no app/.env.") from e
    except openai.RateLimitError as e:
        raise ErroLLM("O limite gratuito da LLM acabou por agora. Espere um pouco "
                      "e tente de novo.") from e
    except openai.APIConnectionError as e:
        raise ErroLLM("Não consegui falar com a LLM. Confira sua internet.") from e
    except openai.APIError as e:
        raise ErroLLM(f"A LLM respondeu com erro: {e}") from e
    return r.choices[0].message.content or ""


# ---------------------------------------------------------------- interpretar

@lru_cache(maxsize=1)
def _locais() -> str:
    r = prolog.consultar({"acao": "locais"})
    partes = {k: v for d in r["ok"]["locais"] for k, v in d.items()}
    return ", ".join(partes["estacoes"] + partes["apelidos"] + partes["bairros"])


PROMPT_INTERPRETAR = """Você traduz perguntas sobre os trens urbanos do Rio de Janeiro \
(antiga SuperVia) para um JSON. Responda SÓ com o JSON, sem texto em volta.

Formato:
{{"acao": "rota" | "info_ramal" | "conversa",
  "origem": nome, "destino": nome,      (só para rota)
  "ramal": nome,                         (só para info_ramal)
  "dia": "segunda_a_sexta" | "sabado" | "domingo_feriado",
  "hora": [hora, minuto]}}

Regras:
- Nomes em minúsculas, sem acento, com _ no lugar de espaço. Ex.: "Méier" -> "meier",
  "Central" -> "central_do_brasil", "Engenhão" -> "engenhao".
- Use um nome desta lista sempre que o lugar estiver nela: {locais}.
  Se o lugar não estiver na lista (ex.: Copacabana), escreva o nome assim mesmo.
- "ramal" é um destes: {ramais}.
- Se a pessoa não disser o dia, use "{dia}". Se não disser a hora, use [{h}, {m}].
  "hoje à noite" = [20, 0]; "de manhã" = [8, 0]; "segunda"..."sexta" = "segunda_a_sexta";
  "domingo" ou "feriado" = "domingo_feriado".
- "rota": quer ir de um lugar a outro. Se só disser o destino, origem = "".
- "info_ramal": pergunta como um ramal funciona (horário, expresso, parador).
- "conversa": cumprimento, agradecimento ou assunto que não é trem.

Exemplos:
"Quero ir do Méier para Bangu no sábado" ->
{{"acao": "rota", "origem": "meier", "destino": "bangu", "dia": "sabado", "hora": [{h}, {m}]}}
"Como funciona o ramal Japeri no domingo?" ->
{{"acao": "info_ramal", "ramal": "japeri", "dia": "domingo_feriado", "hora": [{h}, {m}]}}
"Oi, tudo bem?" -> {{"acao": "conversa"}}"""


def normalizar(texto: str) -> str:
    """'Engenho de Dentro' -> 'engenho_de_dentro'."""
    sem_acento = unicodedata.normalize("NFKD", str(texto)).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", sem_acento.lower()).strip("_")


def validar(dados: dict, dia: str, hora: tuple[int, int]) -> dict:
    """Confere o JSON da LLM e devolve um pedido seguro para o Prolog.

    Levanta ValueError se não der para confiar no JSON.
    """
    if not isinstance(dados, dict):
        raise ValueError("a resposta não é um objeto JSON")
    acao = dados.get("acao")
    if acao == "conversa":
        return {"acao": "conversa"}

    d = dados.get("dia", dia)
    d = d if d in DIAS else dia
    h = dados.get("hora")
    valida = (isinstance(h, list) and len(h) == 2 and all(isinstance(x, int) for x in h)
              and 0 <= h[0] <= 23 and 0 <= h[1] <= 59)
    h = h if valida else list(hora)

    if acao == "rota":
        origem, destino = normalizar(dados.get("origem", "")), normalizar(dados.get("destino", ""))
        if not origem or not destino:
            return {"acao": "falta_local", "origem": origem, "destino": destino}
        for nome in (origem, destino):
            if not NOME.match(nome):
                raise ValueError(f"nome inválido: {nome!r}")
        return {"acao": "rota", "origem": origem, "destino": destino, "dia": d, "hora": h}
    if acao == "info_ramal":
        ramal = normalizar(dados.get("ramal", ""))
        if ramal not in RAMAIS:
            raise ValueError(f"ramal inválido: {ramal!r}")
        return {"acao": "info_ramal", "ramal": ramal, "dia": d}
    raise ValueError(f"ação inválida: {acao!r}")


def _json_da_resposta(texto: str) -> dict:
    # Alguns modelos embrulham o JSON em ```json ... ```.
    inicio, fim = texto.find("{"), texto.rfind("}")
    if inicio < 0 or fim < inicio:
        raise ValueError("não veio JSON")
    return json.loads(texto[inicio:fim + 1])


def interpretar(texto: str, dia: str, hora: tuple[int, int]) -> dict:
    sistema = PROMPT_INTERPRETAR.format(locais=_locais(), ramais=", ".join(RAMAIS),
                                        dia=dia, h=hora[0], m=hora[1])
    ultimo_erro = None
    for _ in range(2):  # uma tentativa extra se o JSON vier quebrado
        try:
            return validar(_json_da_resposta(_chat(sistema, texto, json_mode=True)), dia, hora)
        except (ValueError, json.JSONDecodeError) as e:
            ultimo_erro = e
    raise ErroLLM("Não entendi a pergunta. Tente algo como: "
                  "\"Como vou de Piedade para a Central no sábado?\"") from ultimo_erro


# ---------------------------------------------------------------- responder

PROMPT_RESPONDER = """Você é a "SuperVia IA", assistente dos trens urbanos do Rio. \
Escreva em português do Brasil, simpático e curto, a resposta para a pergunta do \
usuário usando SÓ os dados do JSON abaixo. Nunca invente estação, horário ou ramal.

Como ler o JSON (veio do motor de rotas): {{"f": x}} é f(x) e {{"f": [a, b]}} é f(a, b).
- "embarque": [ramal, {{"sentido": terminal}}, de, ate, {{"paradas": n}}]
  -> "Pegue o ramal X, sentido T, em DE e desça em ATE (n paradas)."
- "baldeacao": [estacao, {{"de": A}}, {{"para": B}}] -> troque de trem nessa estação.
- avisos: "expresso" = o ramal está expresso entre as duas estações e pula as intermediárias;
  "parador" = hoje o ramal para em todas; "origem_por_bairro"/"destino_por_bairro" = o lugar
  foi trocado pela estação mais próxima (diga qual); "ultima_viagem_proxima" = o ramal
  fecha em menos de 30 min.
- "alternativas": outra estação onde a mesma baldeação também funciona.
- erros: "local_desconhecido" = esse lugar não tem trem (sugira dizer um bairro próximo
  com estação); "fora_de_operacao" = não tem trem nesse horário (diga quando abre);
  "mesma_estacao"; "sem_rota"; "falta_local" = pergunte de onde ou para onde a pessoa vai.
- "info": [ramal, dia, funcionamento(início, fim), intervalo(pico, vale), modo,
  trecho_expresso, integracoes, observacoes]. Horas vêm como [h, m].

Formato: passos numerados para rotas. Escreva os nomes com acento e maiúscula
("meier" -> "Méier", "central_do_brasil" -> "Central do Brasil"). Sem markdown pesado."""

PROMPT_CONVERSA = """Você é a "SuperVia IA", assistente dos trens urbanos do Rio. \
Responda em português, em uma ou duas frases simpáticas. Se o assunto não for trem, \
diga com gentileza que só sabe ajudar com rotas e ramais de trem e dê um exemplo de pergunta."""


def responder(pergunta: str, pedido: dict, resultado: dict | None) -> str:
    if resultado is None:
        return _chat(PROMPT_CONVERSA, pergunta).strip()
    dados = json.dumps({"pedido": pedido, "resultado": resultado}, ensure_ascii=False)
    return _chat(PROMPT_RESPONDER, f"Pergunta: {pergunta}\n\nJSON: {dados}").strip()


if __name__ == "__main__" and "--modelos" in sys.argv:
    try:
        for m in _cliente().models.list():
            print(m.id)
    except (ErroLLM, openai.APIError) as e:
        print(e)
