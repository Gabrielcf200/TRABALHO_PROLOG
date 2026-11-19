# Base de dados da malha (estacoes.pl)

Atende a seção 1 do [pedido original](../pedido-original.md).

> **Aviso:** as listas abaixo vêm de conhecimento geral, não de uma fonte oficial atual. A SuperVia está trocando de concessão, então estações podem ter sido abertas, fechadas ou renomeadas. Os trechos marcados **(a conferir)** precisam ser checados no site ou no mapa oficial durante a [etapa 01](../etapas/01-base-de-dados.md).

## Nomes

- Toda estação, ramal e bairro é um átomo em minúsculas, sem acento, com `_` no lugar do espaço: `central_do_brasil`, `meier`, `quintino_bocaiuva`.
- O nome atual vale como nome oficial. Nomes antigos ou populares viram apelidos: `apelido(olimpica_de_engenho_de_dentro, engenho_de_dentro)`, `apelido(central, central_do_brasil)`.
- O Python manda o átomo. Normalizar o texto (tirar acento etc.) é tarefa do Python, não do Prolog.

## Fatos

| Fato | Significado |
|------|-------------|
| `ramal(Ramal, Tipo)` | `Tipo` é `principal` ou `extensao` |
| `extensao_de(Extensao, RamalPai, EstacaoDeConexao)` | ex.: `extensao_de(paracambi, japeri, japeri)` |
| `estacao_ramal(Estacao, Ramal, Posicao)` | `Posicao` = 1 no início do ramal, sobe até o terminal |
| `integracao(Estacao)` | estação de baldeação (fato explícito, não derivado) |
| `bairro_estacao(BairroOuLocal, Estacao)` | bairro ou ponto de referência → estação mais próxima |
| `apelido(Nome, NomeOficial)` | nome alternativo de estação |

A posição define a ordem e o sentido: andar para posições maiores é ir **sentido terminal**, e para posições menores é ir **sentido central_do_brasil**.

## Ramais principais

**deodoro** (parador, Central → Deodoro):
central_do_brasil, praca_da_bandeira, sao_cristovao, maracana, mangueira, sao_francisco_xavier, riachuelo, sampaio, engenho_novo, meier, todos_os_santos, engenho_de_dentro, piedade, quintino_bocaiuva, cascadura, madureira, oswaldo_cruz, bento_ribeiro, marechal_hermes, deodoro.

**santa_cruz**: o trecho Central → Deodoro do ramal deodoro, depois
vila_militar, magalhaes_bastos, realengo, padre_miguel, guilherme_da_silveira, bangu, senador_camara, santissimo, augusto_vasconcelos, campo_grande, benjamin_do_monte, inhoaiba, cosmos, paciencia, tancredo_neves, santa_cruz.

**japeri**: o trecho Central → Deodoro, depois
ricardo_de_albuquerque, anchieta, olinda, nilopolis, edson_passos, mesquita, presidente_juscelino, nova_iguacu, comendador_soares, austin, queimados, engenheiro_pedreira, japeri.

**belford_roxo** (a conferir: trecho inicial e se parte da Central):
central_do_brasil, sao_cristovao, triagem, manguinhos, jacarezinho, del_castilho, pilares, tomas_coelho, cavalcanti, mercadao_de_madureira, rocha_miranda, honorio_gurgel, barros_filho, costa_barros, pavuna, sao_joao_de_meriti, vila_rosali, agostinho_porto, coelho_da_rocha, belford_roxo.

**saracuruna** (a conferir: trecho inicial):
central_do_brasil, sao_cristovao, triagem, manguinhos, bonsucesso, ramos, olaria, penha, penha_circular, bras_de_pina, cordovil, parada_de_lucas, vigario_geral, duque_de_caxias, corte_oito, gramacho, campos_eliseos, jardim_primavera, saracuruna.

## Extensões

| Extensão | Sai de | Estações (a conferir) |
|----------|--------|------------------------|
| paracambi | japeri | japeri, paracambi |
| vila_inhomirim | saracuruna | saracuruna, jardim_nazareno, imbarie, manoel_belo, parada_angelica, parada_morabi, piabeta, vila_inhomirim |
| guapimirim | saracuruna | saracuruna, imbarie (tronco compartilhado), …, guapimirim |

As extensões são operadas à parte (trem diesel ou serviço próprio), então ir do ramal pai para a extensão **sempre** conta como baldeação.

## Estações de integração (mínimo)

central_do_brasil, sao_cristovao, maracana, engenho_de_dentro, madureira, deodoro, japeri, saracuruna, gramacho.

- `madureira` ↔ `mercadao_de_madureira` são estações diferentes, ligadas a pé (a conferir se entram como baldeação a pé).
- Integrações com metrô e BRT ficam fora do escopo; podem entrar depois só como observação textual.

## Bairros e locais (mínimo para a etapa 01)

Todo bairro que tem estação com o mesmo nome mapeia para ela (piedade → piedade, meier → meier, bangu → bangu…). Além disso:

| Bairro/local | Estação |
|--------------|---------|
| centro | central_do_brasil |
| saara, presidente_vargas | central_do_brasil |
| tijuca, uerj | maracana |
| estadio_maracana | maracana |
| quinta_da_boa_vista | sao_cristovao |
| engenhao, estadio_nilton_santos | engenho_de_dentro |
| vila_isabel | sao_francisco_xavier |
| baixada, nova_iguacu_centro | nova_iguacu |
| caxias | duque_de_caxias |

A lista cresce conforme o Python encontrar bairros que não conhece (o erro `local_desconhecido` avisa isso; ver [contrato-python.md](contrato-python.md)).
