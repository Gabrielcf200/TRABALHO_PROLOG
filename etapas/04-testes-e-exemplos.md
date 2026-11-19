# Etapa 04 — Testes e exemplos de consulta

**Objetivo:** provar que tudo funciona e deixar consultas prontas para o Gabriel e para quem fizer a camada Python.

**Depende de:** [etapa 03](03-roteador.md).

## Entregáveis

1. `testes/testes.pl` (plunit) com **todos** os critérios de aceite das etapas 01, 02 e 03.
2. Uma seção `EXEMPLOS DE CONSULTAS` no fim de `src/main.pl`, em comentário, com as consultas e a resposta esperada de cada uma:
   - Trajeto direto: `rota(meier, central_do_brasil, segunda_a_sexta, hora(9,0), R).`
   - Baldeação em dia útil: `rota(piedade, nilopolis, segunda_a_sexta, hora(7,30), R).`
   - A mesma viagem no fim de semana: `rota(piedade, nilopolis, sabado, hora(10,0), R).`
   - Funcionamento de ramal: `info_ramal(japeri, segunda_a_sexta, R).` e `info_ramal(japeri, domingo_feriado, R).`
   - Fora do horário: `rota(meier, japeri, segunda_a_sexta, hora(2,0), R).`
   - Bairro em vez de estação: `rota(tijuca, bangu, sabado, hora(15,0), R).`
   - Extensão: `rota(nova_iguacu, paracambi, segunda_a_sexta, hora(10,0), R).`
3. Um teste de "contrato": para uma amostra de consultas, a resposta tem exatamente o formato de [contrato-python.md](../spec/contrato-python.md) (`ok/1` ou `erro/1`, campos na ordem certa).

## Critérios de aceite

- `swipl -g run_tests -t halt testes/testes.pl` termina com código 0.
- Cada exemplo da seção, colado no `swipl`, dá a resposta escrita no comentário.

## Fora desta etapa

A camada Python e o LLM. São outro projeto, que só depende do contrato.
