# Etapa 02 — Operação e calendário

> **Concluída em 2026-11-19.** A grade oficial da TrensRJ não foi encontrada; os valores com fonte e as estimativas estão separados em [spec/operacao.md](../spec/operacao.md). A janela do expresso virou dia útil 04:30–21:00 (fonte de 2024), em vez de só o pico. 33 testes passando.

**Objetivo:** `operacao.pl` que responde, para qualquer ramal, dia e hora: se está rodando, em que modo (expresso ou parador), com que intervalo, e em quais estações para.

**Depende de:** [etapa 01](01-base-de-dados.md).
**Spec:** [spec/operacao.md](../spec/operacao.md).

## Passos

1. Conferir os horários e intervalos em fonte oficial e corrigir a tabela do spec.
2. Escrever os fatos `operacao/4`, `intervalo/4`, `faixa/4` e `paradas_expresso/1`.
3. Escrever as regras:
   - `em_operacao(Ramal, Dia, Hora)`
   - `faixa_atual(Dia, Hora, Faixa)` → `pico` ou `vale`
   - `modo(Ramal, Dia, Hora, Modo)` → `expresso` ou `parador`
   - `para_em(Ramal, Estacao, Dia, Hora)`: o ramal para nessa estação nesse momento?
   - `proxima_abertura(Dia, Hora, hora(H,M))`

## Critérios de aceite

- `modo(japeri, segunda_a_sexta, hora(7,30), expresso)` é verdadeiro.
- `modo(japeri, sabado, hora(7,30), parador)` é verdadeiro.
- `modo(japeri, segunda_a_sexta, hora(21,30), parador)` é verdadeiro (fora da janela do expresso).
- `para_em(japeri, piedade, segunda_a_sexta, hora(7,30))` falha; o mesmo com `sabado` dá verdadeiro.
- `para_em(deodoro, piedade, D, H)` é verdadeiro sempre que o ramal deodoro estiver rodando.
- `em_operacao(deodoro, segunda_a_sexta, hora(2,0))` falha.

## Fora desta etapa

Busca de rota.
