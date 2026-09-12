# Bloco Gestão / Dashboard

## Fonte única de verdade

A Gestão não mantém números próprios. Os indicadores são calculados sobre CRM, Orçamentos, Contratos, Eventos e Financeiro. Isso elimina o risco de um card mostrar um número diferente do módulo que o originou.

## Conceitos separados

- **Vendas do período:** soma dos orçamentos aprovados na data em que foram aprovados.
- **Eventos do período:** soma do valor comercial dos contratos cujos eventos acontecem no período.
- **Ticket médio:** valor das vendas dividido pela quantidade de vendas.
- **Recebido/Pago:** somente dinheiro efetivamente movimentado.
- **Caixa operacional:** entradas menos saídas realizadas, sem tratar caução recebida como receita.
- **Inadimplência:** saldo aberto de contas a receber cujo vencimento já passou.
- **Conversão CRM:** leads ganhos dividido pelos leads criados no período.

Dessa forma, vender em setembro uma festa que acontecerá em dezembro aumenta **Vendas de setembro**, mas aumenta **Eventos de dezembro**. Receber uma parcela em outubro afeta o **Caixa de outubro**. São três fatos diferentes e não devem ser misturados.

## Mensal e anual

A função `management_summary` recebe início e fim do período. A mesma regra atende mês, trimestre, ano ou intervalo personalizado sem duplicar fórmulas.

## Alertas de gestão

`management_alerts` começa com inadimplência e conflitos de estoque. A fila operacional **Hoje** continua separada: Gestão mostra riscos e desempenho; Hoje mostra trabalho que precisa ser executado.

## Próximo bloco

Antes de criar novos recursos, executar **Auditoria de Integração do ERP**: reconciliar migrations e nomenclaturas, validar estados entre módulos, revisar RLS/RPCs, corrigir onboarding/trial, revisar dependências e bootstrap do frontend, conectar rotas/shell e preparar CI para typecheck/build. Só depois avançar para recursos sofisticados e IA.
