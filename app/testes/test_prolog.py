"""Testes da ponte Python -> Prolog (usam o swipl de verdade).

Uso: python -m unittest discover app/testes
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from prolog import consultar  # noqa: E402


def campos(lista):
    """[{"origem": "x"}, {"destino": "y"}] -> {"origem": "x", "destino": "y"}"""
    return {k: v for d in lista for k, v in d.items()}


class TestPonte(unittest.TestCase):
    def test_baldeacao_em_dia_util(self):
        r = consultar({"acao": "rota", "origem": "piedade", "destino": "nilopolis",
                       "dia": "segunda_a_sexta", "hora": [7, 30]})
        rota = campos(r["ok"]["rota"])
        self.assertEqual(rota["baldeacoes"], 1)
        self.assertEqual(rota["passos"][1],
                         {"baldeacao": ["madureira", {"de": "deodoro"}, {"para": "japeri"}]})

    def test_sabado_direto(self):
        r = consultar({"acao": "rota", "origem": "piedade", "destino": "nilopolis",
                       "dia": "sabado", "hora": [10, 0]})
        self.assertEqual(campos(r["ok"]["rota"])["baldeacoes"], 0)

    def test_bairro_vira_estacao(self):
        r = consultar({"acao": "resolver_local", "local": "tijuca"})
        self.assertEqual(r, {"ok": {"estacao": "maracana"}})

    def test_local_desconhecido(self):
        r = consultar({"acao": "rota", "origem": "copacabana", "destino": "meier",
                       "dia": "sabado", "hora": [10, 0]})
        self.assertEqual(r, {"erro": {"local_desconhecido": "copacabana"}})

    def test_fora_de_operacao(self):
        r = consultar({"acao": "rota", "origem": "meier", "destino": "japeri",
                       "dia": "segunda_a_sexta", "hora": [2, 0]})
        self.assertEqual(r["erro"]["fora_de_operacao"][2], {"abre": {"hora": [4, 30]}})

    def test_hora_invalida(self):
        r = consultar({"acao": "rota", "origem": "meier", "destino": "japeri",
                       "dia": "sabado", "hora": "meio-dia"})
        self.assertIn("hora_invalida", r["erro"])

    def test_info_ramal(self):
        r = consultar({"acao": "info_ramal", "ramal": "japeri", "dia": "segunda_a_sexta"})
        info = r["ok"]["info"]
        self.assertEqual(info[0], "japeri")
        self.assertEqual(info[4], {"modo": {"expresso": [{"hora": [4, 30]}, {"hora": [21, 0]}]}})

    def test_ramais_do_dia(self):
        r = consultar({"acao": "ramais_do_dia", "dia": "sabado"})
        nomes = [i["info"][0] for i in r["ok"]["ramais"]]
        self.assertEqual(nomes, ["deodoro", "santa_cruz", "japeri", "belford_roxo", "saracuruna"])

    def test_campo_ausente_vira_erro(self):
        r = consultar({"acao": "rota", "origem": "meier"})
        self.assertIn("interno", r["erro"])

    def test_texto_com_codigo_prolog_e_so_um_nome(self):
        # Um nome malicioso vira átomo; nunca é executado.
        r = consultar({"acao": "resolver_local", "local": "halt), shell('dir'"})
        self.assertIn("local_desconhecido", r["erro"])


if __name__ == "__main__":
    unittest.main()
