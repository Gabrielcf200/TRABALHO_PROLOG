# Contrato com o Python

Atende ao "Contexto de Arquitetura" e à seção 4 do [pedido original](../pedido-original.md). É o que o Python pode esperar do Prolog. Qualquer mudança aqui quebra o Python, por isso o formato fica neste arquivo e em nenhum outro.

## Regras gerais

- Só átomos em minúsculas, inteiros, listas e termos compostos. Nada de frase pronta: o texto para o usuário é escrito pelo Python/LLM.
- Toda consulta pública **sempre** termina com sucesso, uma vez só, e devolve `ok(...)` ou `erro(...)`. Nunca falha em silêncio e nunca lança exceção.
- O Python chama via `janus` (ponte oficial SWI-Prolog ↔ Python) ou `pyswip`. A escolha é da camada Python e fica fora deste projeto.
- Carregar com `src/main.pl`.

## Predicados públicos

| Predicado | Resposta |
|-----------|----------|
| `rota(Origem, Destino, Dia, Hora, R)` | `ok(rota(...))` ou `erro(...)` |
| `info_ramal(Ramal, Dia, R)` | `ok(info(...))` ou `erro(...)` |
| `resolver_local(Texto, R)` | `ok(estacao(E))` ou `erro(local_desconhecido(Texto))` |

`Dia` ∈ `segunda_a_sexta`, `sabado`, `domingo_feriado`. `Hora` = `hora(H, M)`.

> O pedido escreve `info_ramal(Ramal, DiaDaSemana, Detalhes)`. Aqui `Detalhes` vem embrulhado em `ok/erro`, para seguir o mesmo padrão das outras consultas.

## Rota

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
  avisos([...]),
  alternativas([...])
))
```

- `passos` está em ordem de viagem e sempre começa e termina com `embarque`.
- `sentido(Terminal)` é a placa do trem: o terminal do ramal (ex.: `sentido(japeri)`) ou, voltando, o início (`sentido(central_do_brasil)`, ou a estação de conexão numa extensão).
- `paradas(N)` = quantas vezes o trem para entre `De` e `Ate`, contando `Ate`.

**Avisos** (zero ou mais):

| Aviso | Quando |
|-------|--------|
| `origem_por_bairro(Texto, Estacao)` | a origem veio de bairro ou apelido |
| `destino_por_bairro(Texto, Estacao)` | o destino veio de bairro ou apelido |
| `expresso(Ramal, De, Ate)` | a rota usa um ramal que está expresso nesse trecho agora |
| `parador(Ramal, Dia)` | a rota usa o trecho expresso de um ramal, mas agora ele é parador |
| `ultima_viagem_proxima(Ramal)` | faltam 30 minutos ou menos para o ramal fechar |

**Alternativas** (zero ou mais): `alternativa(baldeacao(Estacao, de(RamalA), para(RamalB)))`, outra estação mais adiante onde a mesma troca também funciona.

## info_ramal

```
ok(info(Ramal, Dia,
  funcionamento(hora(H1,M1), hora(H2,M2)),
  intervalo(pico(Min), vale(Min)),
  modo(expresso(hora(Ini), hora(Fim)))  |  modo(parador),
  trecho_expresso(De, Ate)  |  nenhum,
  integracoes([Estacao, ...]),
  observacoes([...])
))
```

`modo(expresso(I, F))` = expresso entre `I` e `F` e parador fora disso.

**Observações** possíveis:

| Observação | Significado |
|------------|-------------|
| `expresso_entre_central_e_deodoro` | tem expresso nesse dia |
| `parador_fora_da_janela_do_expresso` | fora da janela, vira parador |
| `parador_o_dia_todo` | ramal com expresso, mas não nesse dia |
| `atende_estacoes_que_o_expresso_pula` | (deodoro) é ele que para nas intermediárias |
| `baldeacao_obrigatoria(Estacao)` | (extensão) entrar nela exige baldeação nessa estação |
| `extensao(Extensao, em(Estacao))` | (ramal pai) dá para seguir para a extensão |

## Erros

| Erro | Quando |
|------|--------|
| `local_desconhecido(X)` | origem ou destino não é estação, apelido nem bairro conhecido |
| `ramal_desconhecido(X)` | `info_ramal` com ramal que não existe |
| `dia_invalido(X)` | dia fora dos três tipos |
| `hora_invalida(X)` | hora fora de `hora(0..23, 0..59)` |
| `mesma_estacao(E)` | origem e destino viram a mesma estação |
| `fora_de_operacao(Dia, Hora, abre(hora(H,M)))` | não há rota porque um ramal da origem ou do destino está fechado; `abre` = próxima abertura do mesmo tipo de dia |
| `sem_rota(Origem, Destino)` | nenhuma rota com até 3 baldeações (não acontece com a malha atual) |
| `interno(Excecao)` | bug no Prolog; o Python deve registrar e pedir desculpas ao usuário |
