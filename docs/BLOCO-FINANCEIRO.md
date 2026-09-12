# Bloco Financeiro Integrado

## Princípio

O Financeiro não é uma planilha paralela. Todo lançamento pode manter vínculo com Contrato, Evento, Cliente e Logística, permitindo rastrear de onde veio cada valor.

## Títulos x caixa

`financial_entries` representa o compromisso: conta a receber ou pagar. `financial_payments` representa dinheiro efetivamente recebido/pago. Assim a Heaven separa corretamente **previsto** de **realizado**.

Pagamentos parciais não alteram o valor original do título. O saldo é calculado pela view `financial_entry_balances`.

## Contrato

A função de geração de recebíveis recebe os valores como parâmetros. A Heaven não impõe percentual de sinal, vencimento ou caução. Cada tenant poderá definir regras padrão e ainda ajustar uma negociação específica.

Podem ser criados sinal, saldo e caução opcional. A caução é marcada como valor reembolsável e não entra como receita operacional no fluxo de caixa.

## Caução

Ao devolver uma caução recebida, a Heaven cria uma conta a pagar de reembolso. O dinheiro só sai do caixa quando esse lançamento for efetivamente pago. Isso preserva histórico e evita um simples checkbox sem trilha financeira.

## Despesas

A mesma estrutura suporta logística, compras, manutenção, taxas, reembolsos e outras despesas. Custos externos de uma operação logística podem gerar lançamentos vinculados ao `logistics_run_id`.

## Caixa

A view `cash_movements` considera somente pagamentos realizados. Ela fornece `signed_amount` para saldo financeiro total e `operating_amount` para resultado operacional, excluindo caução recebida.

## Próximo bloco

**Gestão / Dashboard e indicadores:** vendas do período, eventos/entregas do período, ticket médio, contas a receber/pagar, caixa realizado, inadimplência, conversão do CRM, ocupação operacional e alertas. Os indicadores serão derivados das fontes transacionais, sem números duplicados mantidos manualmente.
