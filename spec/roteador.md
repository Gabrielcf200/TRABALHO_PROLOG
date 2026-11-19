# Roteador e info_ramal (roteador.pl)

Atende a seção 3 do [pedido original](../pedido-original.md). Usa os dados de [dados.md](dados.md) e as regras de [operacao.md](operacao.md). O formato de saída está em [contrato-python.md](contrato-python.md).

## Entradas

`rota(Origem, Destino, Dia, Hora, Resposta)`

- `Origem` e `Destino` podem ser estação, apelido ou bairro. A ordem de resolução é: estação → apelido → `bairro_estacao/2`.
- `Dia` é um dos três tipos de [operacao.md](operacao.md). `Hora` vem como `hora(H, M)`.

## Grafo

- Nó = `no(Estacao, Ramal)`.
- **Andar no trem:** de `no(E1, R)` para `no(E2, R)` quando E1 e E2 são paradas vizinhas de R **no modo vigente** naquele dia e hora. Ou seja, no expresso, piedade não existe para o japeri.
- **Baldeação:** de `no(E, R1)` para `no(E, R2)` quando os dois ramais param em E naquele momento.
- O trecho comum Central–Deodoro é o mesmo trilho para deodoro, japeri e santa_cruz. Ficar no mesmo trem **não** é baldeação: se o japeri parador passa em piedade, quem vai de piedade a nilopolis pega o japeri direto.

## Busca

- Busca em largura (BFS) por camadas de baldeação: primeiro tenta 0 baldeações, depois 1, depois 2… Para na primeira camada que acha o destino. Assim a rota com menos baldeações vem primeiro.
- Empate no número de baldeações → vence a de menos estações percorridas.
- Guardar as estações já visitadas para não andar em círculo. Limite duro de 3 baldeações; acima disso, responde `sem_rota`.
- A resposta é determinística: mesma pergunta, mesma rota.

## Sentido

Para cada trecho num ramal, o sentido é o **terminal** para onde o trem segue:

- Se a posição de destino é maior que a de origem → `sentido(Terminal do ramal)`, ex.: `sentido(santa_cruz)`.
- Se é menor → `sentido(central_do_brasil)`.
- Para extensões, o terminal de ida é o fim da extensão, e o de volta é a estação de conexão (ex.: `sentido(saracuruna)`).

## Caso exigido: Piedade → ramal japeri, segunda_a_sexta, pico

Saída esperada (resumida, sem o `paradas(N)` que o [contrato](contrato-python.md) pede em cada embarque):

1. `embarque(deodoro, sentido(deodoro), piedade, madureira)`
2. `baldeacao(madureira, de(deodoro), para(japeri))`
3. `embarque(japeri, sentido(japeri), madureira, Destino)`

E um aviso explicando o motivo: `aviso(expresso(japeri, central_do_brasil, deodoro))`.

- Ponto de baldeação: a estação de integração mais **próxima** da origem no sentido da viagem que também seja parada do expresso. Para piedade, isso dá madureira, e deodoro fica como alternativa (`alternativa(baldeacao(deodoro))`).
- Mesma viagem no sábado: sai direto `embarque(japeri, sentido(japeri), piedade, Destino)`, com o aviso `aviso(parador(japeri, sabado))`.

## info_ramal/3

`info_ramal(Ramal, Dia, Detalhes)` devolve um único termo:

```
info(Ramal, Dia,
     funcionamento(hora(H1,M1), hora(H2,M2)),
     intervalo(pico(Min), vale(Min)),
     modo(ModoNoPico, ModoNoVale),       % expresso | parador
     trecho_expresso(De, Ate) | nenhum,
     integracoes([Estacao, ...]),
     observacoes([Atomo, ...]))
```

`observacoes` traz átomos fixos que o Python sabe traduzir, por exemplo `expresso_central_deodoro_no_pico`, `vira_parador_no_fim_de_semana`, `baldeacao_para_extensao_em_japeri`.
