# Base de dados da malha (estacoes.pl)

Atende a seção 1 do [pedido original](../pedido-original.md). O código está em [`src/estacoes.pl`](../src/estacoes.pl).

## Operadora

Desde **30/05/2026** quem opera os trens não é mais a SuperVia, e sim a **TrensRJ** (Consórcio Nova Via Mobilidade; leilão em 10/02/2026, contrato em 12/03/2026). O projeto continua com o nome do pedido, e nenhum átomo do código usa o nome da operadora. Fontes: [pt.wikipedia TrensRJ](https://pt.wikipedia.org/wiki/TrensRJ), [Diário do Transporte, 13/03/2026](https://diariodotransporte.com.br/2026/03/13/governo-do-rio-de-janeiro-assina-com-nova-via-mobilidade-dando-inicio-a-periodo-de-transicao-para-saida-da-supervia/).

## Fontes das estações (conferidas em 2026-11-19)

- [en.wikipedia — Deodoro Line](https://en.wikipedia.org/wiki/Deodoro_Line) e [List of SuperVia stations](https://en.wikipedia.org/wiki/List_of_SuperVia_stations)
- [Diário do Rio, 27/01/2026 — todos os ramais e estações](https://diariodorio.com/sabe-andar-de-trem-pelo-rj-confira-todos-os-ramais-e-estacoes-da-supervia/)

O site da SuperVia estava fora do ar e o da TrensRJ ainda não foi consultado. **Nenhuma lista foi conferida em fonte oficial.** Os pontos com uma fonte só estão marcados *(a conferir)*.

## Nomes

- Toda estação, ramal e bairro é um átomo em minúsculas, sem acento, com `_` no lugar do espaço.
- Nome curto e popular vira o átomo oficial do sistema; os outros viram `apelido/2`. Exemplos: `engenho_de_dentro` (apelido `olimpica_de_engenho_de_dentro`, que é o nome usado em 2026), `bento_ribeiro` (apelido `prefeito_bento_ribeiro`), `praca_da_bandeira` (apelido `lauro_muller`, o nome antigo).
- Normalizar o texto do usuário (acento, maiúscula) é tarefa do Python.

## Fatos e predicados

| Predicado | Significado |
|-----------|-------------|
| `ramal(Ramal, Tipo)` | `principal` ou `extensao` |
| `extensao_de(Extensao, RamalPai, EstacaoDeConexao)` | ex.: `extensao_de(paracambi, japeri, japeri)` |
| `estacao_ramal(Estacao, Ramal, Posicao)` | derivado da lista do ramal; 1 = início |
| `vizinhas(Ramal, E1, E2)` | E2 vem logo depois de E1, no sentido do terminal |
| `inicio(Ramal, E)` / `terminal(Ramal, E)` | primeira e última estação |
| `integracao(Estacao)` | estação de baldeação |
| `apelido(Nome, NomeOficial)` | nome alternativo |
| `bairro_estacao(BairroOuLocal, Estacao)` | bairro/referência → estação mais próxima |
| `resolver_local(Texto, R)` | estação → apelido → bairro; `ok(estacao(E))` ou `erro(local_desconhecido(X))` |

Cada ramal é **uma lista** em ordem (`sequencia/2`, privado). Japeri e Santa Cruz são montados a partir do mesmo tronco do deodoro, então o trecho comum não tem como ficar diferente.

Andar para posições maiores = **sentido terminal**. Para posições menores = **sentido central_do_brasil** (ou a estação de conexão, numa extensão).

## Ramais

**deodoro** (tronco, parador):
central_do_brasil, praca_da_bandeira, sao_cristovao, maracana, sao_francisco_xavier, riachuelo, sampaio, engenho_novo, meier, engenho_de_dentro, piedade, quintino_bocaiuva, cascadura, madureira, oswaldo_cruz, bento_ribeiro, marechal_hermes, deodoro.

Fora da lista: **mangueira** (só desembarque desde 2014), **todos_os_santos** e **rocha** (fechadas em 1971), **encantado** (fechada em 1997). Os bairros Mangueira, Todos os Santos e Encantado viram `bairro_estacao/2`.

**santa_cruz** e **japeri**: o tronco acima com **silva_freire** entre meier e engenho_de_dentro (só esses dois ramais param lá; a posição exata é *a conferir*), depois:
- santa_cruz: vila_militar, magalhaes_bastos, realengo, padre_miguel, guilherme_da_silveira, bangu, senador_camara, santissimo, augusto_vasconcelos, campo_grande, benjamim_do_monte, inhoaiba, cosmos, paciencia, tancredo_neves, santa_cruz.
- japeri: ricardo_de_albuquerque, anchieta, olinda, nilopolis, edson_passos, mesquita, presidente_juscelino, nova_iguacu, comendador_soares, austin, queimados, engenheiro_pedreira, japeri.

**belford_roxo** *(uma fonte só)*:
central_do_brasil, sao_cristovao, maracana, triagem, jacarezinho, del_castilho, pilares, tomas_coelho, cavalcanti, mercadao_de_madureira, rocha_miranda, honorio_gurgel, barros_filho, costa_barros, pavuna, vila_rosali, agostinho_porto, coelho_da_rocha, belford_roxo.

**saracuruna** *(uma fonte só)*:
central_do_brasil, sao_cristovao, maracana, triagem, manguinhos, bonsucesso, ramos, olaria, penha, penha_circular, bras_de_pina, cordovil, parada_de_lucas, vigario_geral, duque_de_caxias, corte_oito, gramacho, campos_eliseos, jardim_primavera, saracuruna.

Belford Roxo e Saracuruna passam pela Praça da Bandeira sem parar.

## Extensões

As extensões têm operação própria, então entrar nelas sempre conta como baldeação.

| Extensão | Estações |
|----------|----------|
| paracambi | japeri, lages, paracambi |
| vila_inhomirim | saracuruna, parada_morabi, imbarie, manoel_belo, parada_angelica, piabeta, fragoso, vila_inhomirim |
| guapimirim *(a conferir)* | saracuruna, parque_estrela, santa_dalila, surui, santa_guilhermina, iriri, mage, jardim_nova_marilia, jororo, citrolandia, parada_ideal, jardim_guapimirim, parada_modelo, parada_bananal, guapimirim |

A fonte começa Guapimirim em Parque Estrela. A ligação com Saracuruna é hipótese minha.

## Integrações

central_do_brasil, sao_cristovao, maracana, triagem, engenho_de_dentro, madureira, deodoro, japeri, saracuruna.

- **gramacho** saiu da lista: só o ramal saracuruna para lá hoje, então não há para onde baldear. Se voltar a existir serviço Gramacho–Saracuruna separado, entra de novo.
- **madureira** ↔ **mercadao_de_madureira** são estações diferentes. A baldeação a pé entre as duas fica fora do escopo por enquanto.
- Metrô e BRT ficam fora do escopo.

## Bairros e locais

O bairro que tem estação com o mesmo nome já é resolvido direto. Os outros estão em `bairro_estacao/2`: centro, saara e presidente_vargas → central_do_brasil; tijuca, uerj, estadio_maracana e mangueira → maracana; quinta_da_boa_vista → sao_cristovao; vila_isabel → sao_francisco_xavier; estadio_nilton_santos → engenho_de_dentro; todos_os_santos → meier; encantado → piedade; caxias → duque_de_caxias; sao_joao_de_meriti → pavuna; nova_iguacu_centro e baixada → nova_iguacu.

A lista cresce conforme o Python receber `erro(local_desconhecido(X))`.
