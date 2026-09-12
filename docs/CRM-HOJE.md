# CRM e Hoje — princípio de produto

A Heaven é um produto comercial independente. O Sistema LHL serviu para revelar um problema real de operação: um lead pode existir no CRM e ainda assim ser esquecido se ninguém abrir a tela correta. A solução da Heaven generaliza esse aprendizado para qualquer empresa de festas.

## Novo lead

Todo lead novo pertence obrigatoriamente a um `company_id`. Enquanto estiver com status `novo`, ele aparece como pendência acionável na tela **Hoje**. O card mostra somente o contexto necessário para agir e oferece **Chamar no WhatsApp** quando existe telefone.

Ao iniciar o contato pelo card, o lead passa para `em_atendimento` e registra o primeiro contato. Assim ele deixa a fila de novos leads sem ser excluído do CRM.

## Funil inicial

`novo → em_atendimento → orcamento → negociacao → ganho | perdido`

Esse funil é uma base de produto, não uma reprodução do processo interno de nenhuma empresa específica. Futuramente etapas personalizadas poderão ser oferecidas por plano/configuração sem comprometer os estados essenciais usados por automações e indicadores.

## Regra de UX

A tela Hoje não é outro CRM. Ela é uma fila de ação. Dados completos e histórico ficam no CRM; Hoje responde apenas o que precisa de atenção agora.

## Próxima conexão

O próximo passo é concluir a lista/kanban do CRM e implementar a conversão sem redigitação:

`Lead → Orçamento → Cliente → Contrato`.
