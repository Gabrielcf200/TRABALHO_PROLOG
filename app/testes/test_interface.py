"""Teste de fumaça da janela: abre, troca o dia, envia uma pergunta e confere as bolhas.

Usa uma resposta falsa no lugar da LLM, então roda sem internet e sem chave.
"""
import sys
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import main  # noqa: E402


def esperar(app, condicao, segundos=10):
    fim = time.time() + segundos
    while time.time() < fim:
        app.update()
        if condicao():
            return True
        time.sleep(0.05)
    return False


def textos(app):
    """Textos das bolhas, na ordem."""
    return [q.winfo_children()[1].cget("text") for q in app.historico.winfo_children()]


class TestInterface(unittest.TestCase):
    def setUp(self):
        self.original = main.pipeline.perguntar
        main.pipeline.perguntar = lambda texto, dia: f"resposta para {texto} ({dia})"
        self.app = main.App()
        self.app.withdraw()

    def tearDown(self):
        main.pipeline.perguntar = self.original
        self.app.destroy()

    def test_ramais_aparecem_e_mudam_com_o_dia(self):
        def ramais():
            return [r.cget("text") for r in self.app.caixa_ramais.winfo_children()]
        self.assertTrue(esperar(self.app, lambda: "• Japeri (Expresso)" in ramais()))
        self.app.trocar_dia("Sábado")
        self.assertTrue(esperar(self.app, lambda: "• Japeri (Parador)" in ramais()))

    def test_enviar_mostra_espera_e_depois_resposta(self):
        self.app.entrada.insert(0, "do Méier para Bangu")
        self.app.enviar()
        msgs = textos(self.app)
        self.assertEqual(msgs[1], "do Méier para Bangu")
        self.assertIn(msgs[2], main.ESPERA)
        self.assertEqual(self.app.botao.cget("state"), "disabled")
        self.assertTrue(esperar(self.app, lambda: textos(self.app)[2].startswith("resposta")))
        self.assertEqual(textos(self.app)[2], "resposta para do Méier para Bangu (segunda_a_sexta)")
        self.assertEqual(self.app.botao.cget("state"), "normal")
        self.assertEqual(self.app.entrada.get(), "")

    def test_texto_vazio_nao_envia(self):
        self.app.enviar()
        self.assertEqual(len(textos(self.app)), 1)

    def test_limpar_volta_para_boas_vindas(self):
        self.app.bolha("Você", "oi")
        self.app.limpar()
        self.assertEqual(textos(self.app), [main.BOAS_VINDAS])


if __name__ == "__main__":
    unittest.main()
