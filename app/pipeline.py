"""Liga as partes: texto -> llm.interpretar -> prolog.consultar -> llm.responder."""
from datetime import datetime

import llm
import prolog

NOMES_RAMAIS = {"deodoro": "Deodoro", "santa_cruz": "Santa Cruz", "japeri": "Japeri",
                "belford_roxo": "Belford Roxo", "saracuruna": "Saracuruna"}


def perguntar(texto: str, dia: str, hora: tuple[int, int] | None = None,
              _llm=llm, _prolog=prolog) -> str:
    """Devolve sempre um texto para o chat, mesmo quando algo dá errado."""
    if hora is None:
        agora = datetime.now()
        hora = (agora.hour, agora.minute)
    try:
        pedido = _llm.interpretar(texto, dia, hora)
        if pedido["acao"] == "conversa":
            return _llm.responder(texto, pedido, None)
        if pedido["acao"] == "falta_local":
            resultado = {"erro": {"falta_local": [pedido["origem"], pedido["destino"]]}}
        else:
            resultado = _prolog.consultar(pedido)
        return _llm.responder(texto, pedido, resultado)
    except llm.ErroLLM as e:
        return str(e)
    except prolog.ErroProlog as e:
        return f"O motor de rotas falhou: {e}"


def ramais_ativos(dia: str, _prolog=prolog) -> list[tuple[str, str]]:
    """[("Japeri", "Expresso"), ...] para a barra lateral."""
    r = _prolog.consultar({"acao": "ramais_do_dia", "dia": dia})
    linhas = []
    for item in r.get("ok", {}).get("ramais", []):
        ramal, modo = item["info"][0], item["info"][4]["modo"]
        linhas.append((NOMES_RAMAIS.get(ramal, ramal), "Parador" if modo == "parador" else "Expresso"))
    return linhas
