# SuperVia-Prolog

Núcleo de regras em SWI-Prolog para rotas de trem da SuperVia (Rio de Janeiro), estilo Moovit. Uma camada Python + LLM (outro projeto) traduz a pergunta do usuário em consulta Prolog e a resposta de volta em texto.

**Tecnologias:** SWI-Prolog 11 (funciona a partir do 9), plunit (testes).

## Pasta

| Arquivo | O que tem |
|---------|-----------|
| [pedido-original.md](pedido-original.md) | o pedido do Gabriel, sem alterações |
| [spec/dados.md](spec/dados.md) | ramais, extensões, estações, integrações, bairros |
| [spec/operacao.md](spec/operacao.md) | calendário, horários, intervalos, expresso × parador |
| [spec/roteador.md](spec/roteador.md) | busca de rota, sentido, baldeação, `info_ramal/3` |
| [spec/contrato-python.md](spec/contrato-python.md) | formato exato das respostas para o Python |
| [etapas/00-ambiente.md](etapas/00-ambiente.md) | instalar e montar o esqueleto |
| [etapas/01-base-de-dados.md](etapas/01-base-de-dados.md) | `estacoes.pl` |
| [etapas/02-operacao.md](etapas/02-operacao.md) | `operacao.pl` |
| [etapas/03-roteador.md](etapas/03-roteador.md) | `roteador.pl` |
| [etapas/04-testes-e-exemplos.md](etapas/04-testes-e-exemplos.md) | testes e consultas de exemplo |

As etapas vão em ordem: cada uma depende da anterior.

## Como rodar (depois da etapa 00)

```bash
winget install SWI-Prolog.SWI-Prolog
swipl src/main.pl
swipl -g run_tests -t halt testes/testes.pl
```

## Estado

Etapas 00 a 03 concluídas: estações em `src/estacoes.pl`, horários e expresso × parador em `src/operacao.pl`, rotas e `info_ramal/3` em `src/roteador.pl`. Próximo passo: [etapa 04](etapas/04-testes-e-exemplos.md) (exemplos de consulta e teste de contrato).

Desde 30/05/2026 a operadora dos trens é a TrensRJ, não mais a SuperVia (detalhes em [spec/dados.md](spec/dados.md)).
