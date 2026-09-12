# Bloco Contratos — orçamento aprovado como origem

O contrato da Heaven não deve ser um segundo cadastro. Ele nasce de um orçamento aprovado e de um cliente já identificado.

## Snapshot

No momento da geração, o contrato congela quatro conjuntos de dados: cliente, evento, condições comerciais e itens negociados. Isso é proposital: se o telefone do cliente, endereço cadastral, preço atual de um kit ou descrição de catálogo mudar depois, o contrato existente continua representando exatamente o que foi negociado naquele momento.

## Fluxo

`Lead → Orçamento → aprovação → Cliente → Contrato`

A criação exige orçamento `aprovado` e cliente vinculado. A restrição `unique(company_id, quote_id)` evita contratos duplicados acidentalmente para o mesmo orçamento.

## Próximo bloco

A próxima camada será **Evento/Reserva + Agenda**. Um contrato ativo passará a originar a operação: data do evento, logística, reservas de estoque, tarefas e alertas da tela Hoje. Financeiro e produção serão ligados ao evento/contrato, sem criar cadastros paralelos.
