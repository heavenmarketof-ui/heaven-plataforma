# Bloco Produção / Separação + Logística

## Produção

A Heaven transforma o Evento em uma ordem operacional. A ordem não replica itens: ela usa diretamente as reservas de estoque e o checklist de separação.

Fluxo base:

`Aguardando → Em separação → Pronto → Liberado → Concluído`

Um evento só pode ser marcado como **Pronto** quando todos os itens do checklist de separação estiverem `OK`. Isso evita liberar uma festa incompleta apenas porque alguém alterou manualmente um status.

## Logística

As operações configuradas no Evento são espelhadas para o painel logístico. Retirada, entrega, montagem, desmontagem e devolução podem coexistir ou não, de acordo com o modelo de cada empresa.

Cada execução pode possuir responsável, janela de horário, endereço, contato, prestador externo, referência externa, custo e andamento:

`Planejado → Confirmado → Em rota → No local → Concluído`

Isso permite tanto equipe própria quanto serviços externos sem hardcode de fornecedor.

## Encerramento operacional

O evento não é encerrado apenas porque a data passou. A Heaven valida operações logísticas abertas e, quando existe estoque reservado, exige checklist de devolução sem pendências. Só então reservas passam para `devolvida`, produção para `concluido` e evento para `concluido`.

Avarias/perdas continuam como incidentes rastreáveis e poderão gerar manutenção/cobrança no Financeiro.

## Painel de Produção

A view `production_board` entrega evento, prazo de separação, responsável e progresso do checklist. Ela é a base para cards como **A preparar**, **Em separação**, **Prontos** e **Hoje**.

## Próximo bloco

**Financeiro integrado ao ciclo comercial e operacional:** contas a receber/pagar, parcelas, sinal, saldo, caução opcional/configurável, custos de logística/compra, fluxo de caixa e vínculo obrigatório com tenant; depois conectaremos os indicadores de Gestão.
