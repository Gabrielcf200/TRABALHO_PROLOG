# Operação e calendário (operacao.pl)

Atende a seção 2 do [pedido original](../pedido-original.md). O código está em [`src/operacao.pl`](../src/operacao.pl). As estações citadas aqui estão em [dados.md](dados.md).

> **Aviso:** a grade oficial da TrensRJ (operadora desde 30/05/2026) não foi encontrada publicada. Os valores abaixo misturam dados pontuais de 2026 (a maioria ainda da era SuperVia) com estimativas. Cada valor é um fato isolado na seção "Valores" do código, então dá para corrigir sem mexer em regra. Fonte oficial para conferir: o planejador em trensrj.com.br ou o 0800 726 9494.

## Tipos de dia

`segunda_a_sexta`, `sabado`, `domingo_feriado`.

- O Python manda um desses três átomos. Converter "segunda-feira" ou uma data, e saber se é feriado, é tarefa do Python.
- Dias especiais (eleição, show, manutenção) ficam fora do escopo.

## Hora

- A hora entra como `hora(H, M)`, com H de 0 a 23 e M de 0 a 59 (`hora_valida/1`).
- Por dentro tudo vira minutos (`minutos/2`). A janela vale de `Inicio` (incluído) até `Fim` (excluído).

## Predicados

| Predicado | Significado |
|-----------|-------------|
| `operacao(Ramal, Dia, Inicio, Fim)` | janela de operação; `janela_ramal/4` vence a janela geral do tipo de ramal |
| `faixa(Dia, pico, Inicio, Fim)` | faixas de pico (para o intervalo) |
| `faixa_atual(Dia, Hora, Faixa)` | `pico` ou `vale` |
| `intervalo(Ramal, Dia, Faixa, Min)` | intervalo médio; sem valor específico, usa o padrão do tipo de ramal |
| `paradas_expresso(E)` / `trecho_expresso(Ramal, De, Ate)` | onde o expresso para e em que trecho |
| `em_operacao(Ramal, Dia, Hora)` | o ramal está rodando |
| `modo(Ramal, Dia, Hora, Modo)` | `expresso` ou `parador` |
| `para_em(Ramal, Estacao, Dia, Hora)` | o ramal está rodando e para nessa estação agora |
| `proxima_abertura(Dia, Hora, abre(H))` | primeira abertura depois da hora pedida |

## Valores

**Janela de operação**

| | segunda_a_sexta | sabado | domingo_feriado |
|-|-----------------|--------|-----------------|
| ramais principais | 04:30–23:00 | 05:00–22:00 | 05:00–21:00 |
| extensões | 05:00–21:00 | 05:00–20:00 | 05:00–20:00 |
| belford_roxo | geral | geral | **05:00–17:20** |

- Início: primeiras partidas entre 4h19 e 4h35 ([Mobilidade360, 03/10/2026](https://mobilidade360.com.br/2026/10/03/eleicoes-2026-trensrj-tera-340-viagens/), dia de eleição).
- Belford Roxo no domingo: última saída da Central às 17h20 desde 11/10/2026 ([Diário do Rio, 10/10/2026](https://diariodorio.com/rio-de-janeiro/2026/10/10/ramal-belford-roxo-tera-mais-que-o-dobro-de-viagens-aos-domingos-e-espera-por-trens-cai-pela-metade.html)).
- O resto dos fins de janela é **estimativa**. No dia da eleição, os últimos trens saíram da Central entre 19h52 e 21h33, mas isso não é a grade normal.

**Faixas de pico (dia útil):** 06:00–08:00 e 17:00–19:00 ([Diário do Transporte, 31/01/2026](https://diariodotransporte.com.br/2026/01/31/ramais-belford-roxo-e-saracuruna-terao-reducao-de-intervalo-e-de-tempo-de-viagem-no-sistema-de-trens-do-rio-de-janeiro-a-partir-de-03-de-fevereiro-de-2026/)). Sábado e domingo são sempre vale.

**Intervalo médio (minutos)**

| Ramal | útil, pico | útil, vale | sábado | domingo |
|-------|-----------|-----------|--------|---------|
| deodoro | 10* | 20* | 25* | 35* |
| japeri | 8 | 20* | 25* | 35* |
| santa_cruz | 9 | 20* | 25* | 35* |
| belford_roxo | 15 | 20* | 25* | 50 |
| saracuruna | 12 | 20* | 25* | 35* |
| extensões | 60* | 60* | 60* | 60* |

\* estimativa. Japeri 8 e Santa Cruz 9: [Diário do Transporte, 03/05/2026](https://diariodotransporte.com.br/2026/05/03/supervia-amplia-numero-de-viagens-nos-ramais-japeri-e-santa-cruz-a-partir-desta-terca-feira-05/) (teste de 30 dias da SuperVia). Belford Roxo 15 e Saracuruna 12: Diário do Transporte, 31/01/2026. Belford Roxo 50 no domingo: Diário do Rio, 10/10/2026.

## Regra expresso × parador

1. `japeri` e `santa_cruz` rodam **expressos** entre central_do_brasil e deodoro dentro de `janela_expresso/3`. Nesse trecho só param em central_do_brasil, sao_cristovao, maracana, silva_freire, engenho_de_dentro, madureira e deodoro (lista do Diário do Rio, 27/01/2026). Depois de Deodoro param em todas.
2. Fora da janela (à noite em dia útil, e todo sábado e domingo), viram **paradores** em todo o trecho.
3. `deodoro`, `belford_roxo`, `saracuruna` e as extensões são sempre paradores.

**Janela do expresso: dia útil, 04:30–21:00.** O pedido falava em "horário comercial/pico". A única fonte com horário ([en.wikipedia Japeri Line](https://en.wikipedia.org/wiki/Japeri_Line), dados de março/2024) diz que, em dia útil, até 21h todos os trens Central–Deodoro desses ramais são expressos. Por isso a janela do expresso ficou separada das faixas de pico. Para voltar a "só no pico", basta trocar `janela_expresso/3` pelas mesmas faixas de `faixa/4`.

Fora do escopo: a parada extra em Silva Freire só entre 10h e 15h, e sentidos com horários de expresso diferentes. A fonte de 2024 cita os dois.

Consequência para a rota: em dia útil até 21h, uma estação intermediária do tronco (piedade, meier, riachuelo…) **não** é atendida por japeri nem por santa_cruz. Quem sai dela para esses ramais pega o deodoro e faz baldeação. Ver [roteador.md](roteador.md).

## Fora de operação

Ramal fechado simplesmente some do grafo. Se por isso não sobra rota e algum ramal que atende a origem ou o destino está fechado, a resposta é `erro(fora_de_operacao(Dia, Hora, abre(hora(H,M))))`. Se sobra rota por outro caminho, ela volta normalmente. Depois do último trem, `abre` traz a primeira abertura do **mesmo** tipo de dia, porque o Prolog não sabe qual é o dia seguinte; o Python ajusta isso.
