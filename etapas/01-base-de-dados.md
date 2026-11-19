# Etapa 01 — Base de dados da malha

**Objetivo:** `estacoes.pl` com todos os ramais, extensões, estações em ordem, integrações, apelidos e bairros.

**Depende de:** [etapa 00](00-ambiente.md).
**Spec:** [spec/dados.md](../spec/dados.md).

## Passos

1. Conferir em fonte oficial atual os trechos marcados *(a conferir)* em `spec/dados.md`: o início dos ramais belford_roxo e saracuruna, as estações das extensões, e se `encantado` e `praca_da_bandeira` estão abertas. Corrigir o spec **antes** de codar.
2. Escrever os fatos `ramal/2`, `extensao_de/3`, `estacao_ramal/3`, `integracao/1`, `apelido/2` e `bairro_estacao/2`.
3. Escrever os predicados de apoio: `vizinhas(Ramal, E1, E2)`, `terminal(Ramal, Estacao)`, `estacao_existe(E)` e `resolver_local(Texto, R)`.

## Critérios de aceite (viram testes na etapa 04)

- Cada ramal tem posições 1..N sem buraco e sem repetição.
- O trecho Central–Deodoro é idêntico nos ramais deodoro, japeri e santa_cruz.
- Toda estação de `integracao/1` aparece em pelo menos 2 ramais (ou é conexão de extensão).
- `resolver_local(centro, R)` dá `R = ok(estacao(central_do_brasil))`.
- `resolver_local(olimpica_de_engenho_de_dentro, R)` dá `ok(estacao(engenho_de_dentro))`.
- `resolver_local(xyz, R)` dá `erro(local_desconhecido(xyz))`.

## Fora desta etapa

Horários, modos e rotas.
