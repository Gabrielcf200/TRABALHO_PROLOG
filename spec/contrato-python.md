# Contrato com o Python

Atende ao "Contexto de Arquitetura" e à seção 4 do [pedido original](../pedido-original.md). É o que o Python pode esperar do Prolog. Qualquer mudança aqui quebra o Python, por isso fica neste arquivo e em nenhum outro.

## Regras gerais

- Só átomos em minúsculas, inteiros, listas e termos compostos. Nada de strings com frase pronta: o texto para o usuário é escrito pelo Python/LLM.
- Toda consulta pública **sempre** termina com sucesso, uma vez só (`once`), e devolve `ok(...)` ou `erro(...)`. Ela nunca falha em silêncio e nunca lança exceção para o Python.
- O Python chama via `janus` (ponte oficial SWI-Prolog ↔ Python) ou `pyswip`. A escolha é da camada Python e fica fora deste projeto.

## Predicados públicos

| Predicado | Resposta |
|-----------|----------|
| `rota(Origem, Destino, Dia, Hora, R)` | `ok(rota(...))` ou `erro(...)` |
| `info_ramal(Ramal, Dia, R)` | `ok(info(...))` ou `erro(...)` |
| `resolver_local(Texto, R)` | `ok(estacao(E))` ou `erro(local_desconhecido(Texto))` |

> Observação: o pedido escreve `info_ramal(Ramal, DiaDaSemana, Detalhes)`. Aqui `Detalhes` vem embrulhado em `ok/erro` para manter o mesmo padrão em todas as consultas.

## Forma da rota

```
ok(rota(
  origem(EstacaoOrigem),
  destino(EstacaoDestino),
  passos([
    embarque(Ramal, sentido(Terminal), De, Ate, paradas(N)),
    baldeacao(Estacao, de(RamalA), para(RamalB)),
    embarque(...)
  ]),
  baldeacoes(Quantidade),
  avisos([ aviso(...), ... ]),
  alternativas([ alternativa(...), ... ])
))
```

- `passos` está sempre em ordem de viagem, começa e termina em `embarque`.
- `paradas(N)` = quantas paradas o trem faz entre `De` e `Ate`.
- Avisos possíveis: `expresso(Ramal, De, Ate)`, `parador(Ramal, Dia)`, `origem_por_bairro(Bairro, Estacao)`, `trecho_fechado(Ramal)`, `ultima_viagem_proxima(Ramal)`.

## Erros

| Erro | Quando |
|------|--------|
| `local_desconhecido(X)` | origem ou destino não é estação, apelido nem bairro conhecido |
| `dia_invalido(X)` | dia fora dos três tipos |
| `hora_invalida(X)` | hora fora de `hora(0..23, 0..59)` |
| `fora_de_operacao(Dia, Hora, abre(hora(H,M)))` | nenhum trem roda nesse horário |
| `sem_rota(Origem, Destino)` | nenhuma rota com até 3 baldeações |
| `mesma_estacao(E)` | origem e destino são a mesma estação |
