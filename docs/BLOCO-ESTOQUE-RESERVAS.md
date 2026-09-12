# Bloco Estoque + Reservas + Separação + Devolução

## Princípio

A disponibilidade não é uma quantidade estática. Para uma empresa de festas, o mesmo item pode estar disponível em uma data e comprometido em outra. A Heaven calcula disponibilidade por **item + quantidade + intervalo de tempo**.

## Cadastro

Cada tenant possui categorias e itens próprios. Um item pode controlar quantidade ou funcionar como recurso não quantitativo. SKU, custo de reposição, manutenção e observações são opcionais e pertencem à empresa.

## Reserva por período

A reserva pertence ao Evento. Ela possui `reserved_from` e `reserved_until`, permitindo considerar retirada antecipada, montagem, evento, desmontagem e devolução em vez de comparar apenas a data da festa.

A função de reserva trava a linha do item durante a validação e gravação para reduzir risco de overbooking em duas reservas concorrentes. Se a quantidade disponível for menor que a solicitada, a operação falha em vez de silenciosamente criar conflito.

## Conflitos

`inventory_conflicts` serve como rede adicional de diagnóstico para inconsistências preexistentes/importadas ou alterações posteriores de quantidade. Esses conflitos poderão aparecer em Hoje e no Evento.

## Separação e devolução

O checklist nasce das reservas do evento. Não há redigitação de peças. Existem duas fases independentes:

- `separacao`: o que deveria sair versus o que foi conferido;
- `devolucao`: o que deveria retornar versus o que retornou.

Estados `faltando`, `avariado` e `perdido` permitem abrir incidentes e, posteriormente, alimentar manutenção, cobrança e financeiro.

## Próximo bloco

**Produção/Separação + Logística integrada.** Vamos transformar os checklists e operações em painéis de execução: eventos a preparar, itens pendentes, responsável, retirada/entrega/montagem/devolução e encerramento operacional.
