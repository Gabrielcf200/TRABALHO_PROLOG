"""SuperVia IA — app desktop (CustomTkinter). Uso: python app/main.py

Layout e fluxo: spec/app-desktop.md, seção "Interface".
"""
import queue
import random
import threading

import customtkinter as ctk

import pipeline
import prolog

DIAS = {"Segunda a Sexta": "segunda_a_sexta", "Sábado": "sabado",
        "Domingo e Feriado": "domingo_feriado"}
ESPERA = ["Hmm, deixa eu ver…", "Consultando os trilhos…", "Só um instante, olhando o mapa…",
          "Deixa eu ver qual trem passa aí…", "Conferindo os ramais…"]
BOAS_VINDAS = ("Olá! Me diga de onde você sai e para onde vai, por exemplo: "
               "\"Como vou de Piedade para o Centro no sábado?\". "
               "Também explico como funciona cada ramal.")
LARGURA_TEXTO = 520


class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("SuperVia IA")
        self.geometry("1000x660")
        self.minsize(820, 520)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)
        self.ocupado = False
        self.dia = "segunda_a_sexta"
        # Threads de trabalho não tocam no Tk: põem (função, args) aqui, e a
        # janela executa em _drenar_fila().
        self.fila = queue.Queue()
        self._montar_sidebar()
        self._montar_principal()
        self.limpar()
        self.trocar_dia("Segunda a Sexta")
        self._drenar_fila()

    def _drenar_fila(self):
        while not self.fila.empty():
            funcao, args = self.fila.get_nowait()
            funcao(*args)
        self._id_fila = self.after(80, self._drenar_fila)

    def destroy(self):
        self.after_cancel(self._id_fila)
        super().destroy()

    # ------------------------------------------------------------ layout

    def _montar_sidebar(self):
        side = ctk.CTkFrame(self, width=260, corner_radius=0)
        side.grid(row=0, column=0, sticky="nsw")
        side.grid_propagate(False)
        side.grid_columnconfigure(0, weight=1)
        side.grid_rowconfigure(5, weight=1)

        ctk.CTkLabel(side, text="🚆 SuperVia IA", font=ctk.CTkFont(size=22, weight="bold")
                     ).grid(row=0, column=0, padx=20, pady=(24, 20), sticky="w")
        ctk.CTkLabel(side, text="Dia da Simulação:").grid(row=1, column=0, padx=20, sticky="w")
        self.menu_dia = ctk.CTkOptionMenu(side, values=list(DIAS), command=self.trocar_dia)
        self.menu_dia.grid(row=2, column=0, padx=20, pady=(4, 20), sticky="ew")
        ctk.CTkLabel(side, text="Ramais Ativos:").grid(row=3, column=0, padx=20, sticky="w")
        self.caixa_ramais = ctk.CTkFrame(side, fg_color="transparent")
        self.caixa_ramais.grid(row=4, column=0, padx=20, pady=4, sticky="new")
        ctk.CTkButton(side, text="Limpar Conversa", command=self.limpar
                      ).grid(row=6, column=0, padx=20, pady=20, sticky="ew")

    def _montar_principal(self):
        self.historico = ctk.CTkScrollableFrame(self, label_text="Histórico de Rotas")
        self.historico.grid(row=0, column=1, padx=16, pady=(16, 8), sticky="nsew")
        self.historico.grid_columnconfigure(0, weight=1)

        barra = ctk.CTkFrame(self, fg_color="transparent")
        barra.grid(row=1, column=1, padx=16, pady=(0, 16), sticky="ew")
        barra.grid_columnconfigure(0, weight=1)
        self.entrada = ctk.CTkEntry(barra, height=40,
                                    placeholder_text="Digite origem/destino… ex.: do Méier para Bangu")
        self.entrada.grid(row=0, column=0, sticky="ew")
        self.entrada.bind("<Return>", self.enviar)
        self.botao = ctk.CTkButton(barra, text=">", width=44, height=40, command=self.enviar)
        self.botao.grid(row=0, column=1, padx=(8, 0))
        self.entrada.focus()

    # ------------------------------------------------------------ chat

    def bolha(self, autor: str, texto: str) -> ctk.CTkLabel:
        """Põe uma mensagem no histórico e devolve o rótulo do texto (para trocar depois)."""
        do_usuario = autor == "Você"
        quadro = ctk.CTkFrame(self.historico, corner_radius=12,
                              fg_color=("#dbeafe", "#1e3a5f") if do_usuario else ("gray88", "gray20"))
        quadro.grid(row=len(self.historico.winfo_children()), column=0, pady=6,
                    padx=(80, 4) if do_usuario else (4, 80), sticky="e" if do_usuario else "w")
        ctk.CTkLabel(quadro, text=f"{autor}:", font=ctk.CTkFont(weight="bold")
                     ).pack(anchor="w", padx=12, pady=(8, 0))
        rotulo = ctk.CTkLabel(quadro, text=texto, wraplength=LARGURA_TEXTO, justify="left")
        rotulo.pack(anchor="w", padx=12, pady=(0, 10))
        self._rolar_para_o_fim()
        return rotulo

    def _rolar_para_o_fim(self):
        self.update_idletasks()
        self.historico._parent_canvas.yview_moveto(1.0)

    def enviar(self, _evento=None):
        texto = self.entrada.get().strip()
        if not texto or self.ocupado:
            return
        self.entrada.delete(0, "end")
        self.bolha("Você", texto)
        espera = self.bolha("SuperVia IA", random.choice(ESPERA))
        self._ocupar(True)
        dia = self.dia
        threading.Thread(target=self._processar, args=(texto, dia, espera), daemon=True).start()

    def _processar(self, texto, dia, espera):
        try:
            resposta = pipeline.perguntar(texto, dia)
        except Exception as e:  # noqa: BLE001 — o chat nunca pode travar
            resposta = f"Algo deu errado: {e}"
        self.fila.put((self._mostrar, (espera, resposta)))

    def _mostrar(self, espera, resposta):
        if espera.winfo_exists():  # a conversa pode ter sido limpa enquanto esperava
            espera.configure(text=resposta)
            self._rolar_para_o_fim()
        self._ocupar(False)

    def _ocupar(self, sim: bool):
        self.ocupado = sim
        self.botao.configure(state="disabled" if sim else "normal")

    def limpar(self):
        for filho in self.historico.winfo_children():
            filho.destroy()
        self.bolha("SuperVia IA", BOAS_VINDAS)

    # ------------------------------------------------------------ barra lateral

    def trocar_dia(self, nome: str):
        self.dia = DIAS[nome]
        threading.Thread(target=self._carregar_ramais, args=(self.dia,), daemon=True).start()

    def _carregar_ramais(self, dia):
        try:
            linhas = [f"• {ramal} ({modo})" for ramal, modo in pipeline.ramais_ativos(dia)]
        except prolog.ErroProlog as e:
            linhas = [f"Prolog indisponível: {e}"]
        self.fila.put((self._mostrar_ramais, (dia, linhas)))

    def _mostrar_ramais(self, dia, linhas):
        if dia != self.dia:  # o usuário já trocou de dia de novo
            return
        for filho in self.caixa_ramais.winfo_children():
            filho.destroy()
        for linha in linhas:
            ctk.CTkLabel(self.caixa_ramais, text=linha, wraplength=220, justify="left"
                         ).pack(anchor="w", pady=1)


if __name__ == "__main__":
    ctk.set_appearance_mode("system")
    App().mainloop()
