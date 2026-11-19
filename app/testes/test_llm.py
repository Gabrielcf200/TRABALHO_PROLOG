"""Testes da validação do JSON da LLM e do pipeline, com uma LLM falsa (sem internet).

Uso: python -m unittest discover app/testes
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import llm  # noqa: E402
import pipeline  # noqa: E402

DIA, HORA = "segunda_a_sexta", (7, 30)


class TestValidar(unittest.TestCase):
    def test_rota_completa(self):
        p = llm.validar({"acao": "rota", "origem": "Piedade", "destino": "Engenho de Dentro",
                         "dia": "sabado", "hora": [10, 0]}, DIA, HORA)
        self.assertEqual(p, {"acao": "rota", "origem": "piedade", "destino": "engenho_de_dentro",
                             "dia": "sabado", "hora": [10, 0]})

    def test_acentos_viram_nome_do_prolog(self):
        self.assertEqual(llm.normalizar("Méier"), "meier")
        self.assertEqual(llm.normalizar("  São Cristóvão "), "sao_cristovao")

    def test_dia_e_hora_padrao(self):
        p = llm.validar({"acao": "rota", "origem": "meier", "destino": "bangu"}, DIA, HORA)
        self.assertEqual((p["dia"], p["hora"]), (DIA, [7, 30]))

    def test_dia_e_hora_invalidos_viram_padrao(self):
        p = llm.validar({"acao": "rota", "origem": "meier", "destino": "bangu",
                         "dia": "terca", "hora": [25, 0]}, DIA, HORA)
        self.assertEqual((p["dia"], p["hora"]), (DIA, [7, 30]))

    def test_falta_origem(self):
        p = llm.validar({"acao": "rota", "origem": "", "destino": "meier"}, DIA, HORA)
        self.assertEqual(p["acao"], "falta_local")

    def test_acao_invalida(self):
        with self.assertRaises(ValueError):
            llm.validar({"acao": "apagar_tudo"}, DIA, HORA)

    def test_ramal_invalido(self):
        with self.assertRaises(ValueError):
            llm.validar({"acao": "info_ramal", "ramal": "metro"}, DIA, HORA)

    def test_nome_gigante(self):
        with self.assertRaises(ValueError):
            llm.validar({"acao": "rota", "origem": "a" * 100, "destino": "meier"}, DIA, HORA)

    def test_conversa(self):
        self.assertEqual(llm.validar({"acao": "conversa", "x": 1}, DIA, HORA), {"acao": "conversa"})

    def test_json_embrulhado_em_markdown(self):
        self.assertEqual(llm._json_da_resposta('```json\n{"acao": "conversa"}\n```'),
                         {"acao": "conversa"})


class LLMFalsa:
    """Imita o módulo llm: interpretar devolve um pedido fixo, responder devolve o que recebeu."""
    ErroLLM = llm.ErroLLM

    def __init__(self, pedido):
        self.pedido = pedido

    def interpretar(self, texto, dia, hora):
        return self.pedido

    def responder(self, pergunta, pedido, resultado):
        return f"RESPOSTA {resultado}"


class TestPipeline(unittest.TestCase):
    def test_rota_passa_pelo_prolog_de_verdade(self):
        falsa = LLMFalsa({"acao": "rota", "origem": "engenho_de_dentro", "destino": "meier",
                          "dia": "segunda_a_sexta", "hora": [9, 0]})
        texto = pipeline.perguntar("Quero ir do Engenho de Dentro ao Méier", DIA, HORA, _llm=falsa)
        self.assertIn("'embarque': ['deodoro', {'sentido': 'central_do_brasil'}, "
                      "'engenho_de_dentro', 'meier'", texto)

    def test_conversa_nao_chama_o_prolog(self):
        texto = pipeline.perguntar("oi", DIA, HORA, _llm=LLMFalsa({"acao": "conversa"}),
                                   _prolog=None)
        self.assertEqual(texto, "RESPOSTA None")

    def test_falta_local_nao_chama_o_prolog(self):
        falsa = LLMFalsa({"acao": "falta_local", "origem": "", "destino": "meier"})
        texto = pipeline.perguntar("quero ir pro meier", DIA, HORA, _llm=falsa, _prolog=None)
        self.assertIn("falta_local", texto)

    def test_erro_da_llm_vira_mensagem(self):
        class Quebrada(LLMFalsa):
            def interpretar(self, *_):
                raise llm.ErroLLM("sem internet")
        self.assertEqual(pipeline.perguntar("x", DIA, HORA, _llm=Quebrada(None)), "sem internet")

    def test_sem_chave_avisa_o_que_fazer(self):
        import os
        antiga = os.environ.pop("LLM_API_KEY", None)
        try:
            texto = pipeline.perguntar("oi", DIA, HORA)
        finally:
            if antiga is not None:
                os.environ["LLM_API_KEY"] = antiga
        self.assertIn("LLM_API_KEY", texto)

    def test_ramais_ativos(self):
        self.assertIn(("Japeri", "Expresso"), pipeline.ramais_ativos("segunda_a_sexta"))
        self.assertIn(("Japeri", "Parador"), pipeline.ramais_ativos("sabado"))
        self.assertIn(("Deodoro", "Parador"), pipeline.ramais_ativos("segunda_a_sexta"))


if __name__ == "__main__":
    unittest.main()
