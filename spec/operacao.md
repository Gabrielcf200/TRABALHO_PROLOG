# Operação e calendário (operacao.pl)

Atende a seção 2 do [pedido original](../pedido-original.md). As estações citadas aqui estão em [dados.md](dados.md).

> **Aviso:** os horários e intervalos abaixo são **aproximados** e servem de ponto de partida. Cada valor vira um fato isolado no código, para ser corrigido sem mexer em regra nenhuma. Conferir em fonte oficial na [etapa 02](../etapas/02-operacao.md).

## Tipos de dia

`segunda_a_sexta`, `sabado`, `domingo_feriado`.

- O Python manda um desses três átomos. Converter "segunda-feira" ou uma data em tipo de dia é tarefa do Python.
- Feriado vale como `domingo_feriado`. Quem sabe se a data é feriado é o Python.

## Hora

- A hora entra como `hora(H, M)`, por exemplo `hora(7, 30)`.
- Internamente tudo vira minutos desde 00:00, para comparar.
- A operação não passa da meia-noite (a conferir). Se algum ramal passar, o fim vira um valor maior que 24:00, como `hora(24, 30)`.

## Fatos

| Fato | Significado |
|------|-------------|
| `operacao(Ramal, Dia, Inicio, Fim)` | janela em que o ramal roda, com `hora(H,M)` |
| `intervalo(Ramal, Dia, Faixa, Minutos)` | intervalo médio (headway); `Faixa` é `pico` ou `vale` |
| `faixa(Dia, Faixa, Inicio, Fim)` | quando é pico e quando é vale naquele tipo de dia |
| `paradas_expresso(Estacao)` | onde o expresso para entre Central e Deodoro |

## Valores iniciais (aproximados)

| Ramal | segunda_a_sexta | sabado | domingo_feriado |
|-------|-----------------|--------|-----------------|
| deodoro, santa_cruz, japeri, belford_roxo, saracuruna | 04:30–23:00 | 05:00–22:00 | 05:00–21:00 |
| paracambi, vila_inhomirim, guapimirim | poucas viagens, intervalo de ~60 min ou mais | idem | idem |

Intervalo médio: dia útil, pico ~10 min (deodoro) e ~12 min (japeri e santa_cruz); dia útil, vale ~20 min; sábado ~20–30 min; domingo ~30–40 min.

Faixas de pico em dia útil: 05:00–09:00 e 16:00–20:00. Fora delas, e no sábado e domingo, é vale.

## Regra expresso × parador

O **modo** de cada ramal num dado dia e hora é `expresso` ou `parador`:

1. `japeri` e `santa_cruz` em `segunda_a_sexta` **e** faixa `pico` → `expresso` entre central_do_brasil e deodoro. Nesse trecho só param em: central_do_brasil, sao_cristovao, maracana, engenho_de_dentro, madureira, deodoro. Depois de Deodoro param em todas.
2. Os mesmos ramais em `sabado`, `domingo_feriado`, ou em dia útil fora do pico (vale/madrugada) → `parador` em todo o trecho.
3. `deodoro`, `belford_roxo`, `saracuruna` e as extensões → sempre `parador`.

Consequência para a rota: no pico de dia útil, uma estação intermediária do tronco (piedade, meier, riachuelo…) **não** é atendida por japeri nem por santa_cruz. Quem sai dela para esses ramais precisa pegar o deodoro e fazer baldeação. Ver [roteador.md](roteador.md).

> Pelo pedido, "pico" é a janela em que o expresso roda. Se na vida real o expresso rodar o dia útil inteiro, basta trocar as faixas em `faixa/4`; a regra continua a mesma.

## Fora de operação

Se a hora pedida está fora de `operacao/4` em **todos** os ramais da rota, a resposta é um erro com o próximo horário de abertura (ver [contrato-python.md](contrato-python.md)). Se só um trecho estiver fechado (uma extensão, por exemplo), a rota volta com um aviso.
