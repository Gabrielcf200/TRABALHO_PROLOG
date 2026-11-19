"""Ponte com o núcleo Prolog: manda um pedido em JSON para src/api.pl e lê a resposta.

O Python nunca monta código Prolog. Só passa dados (spec/app-desktop.md).
"""
import json
import os
import shutil
import subprocess
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
API = RAIZ / "src" / "api.pl"
SWIPL_WINDOWS = Path(r"C:\Program Files\swipl\bin\swipl.exe")


class ErroProlog(RuntimeError):
    """O swipl não rodou ou não devolveu JSON."""


def achar_swipl() -> str:
    candidato = os.environ.get("SWIPL") or shutil.which("swipl")
    if candidato:
        return candidato
    if SWIPL_WINDOWS.exists():
        return str(SWIPL_WINDOWS)
    raise ErroProlog("SWI-Prolog não encontrado. Instale ou defina SWIPL no .env.")


def consultar(pedido: dict, timeout: float = 10) -> dict:
    """Ex.: consultar({"acao": "rota", "origem": "meier", ...}) -> {"ok": {...}} ou {"erro": {...}}."""
    # No Windows, sem isso cada consulta pisca uma janela preta de console.
    sem_janela = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    try:
        r = subprocess.run(
            [achar_swipl(), str(API)],
            input=json.dumps(pedido, ensure_ascii=False),
            capture_output=True, text=True, encoding="utf-8",
            timeout=timeout, creationflags=sem_janela,
        )
    except subprocess.TimeoutExpired as e:
        raise ErroProlog(f"O Prolog demorou mais de {timeout}s.") from e
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError as e:
        raise ErroProlog(f"Resposta inválida do Prolog: {r.stdout!r} {r.stderr!r}") from e
