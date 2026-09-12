# Bloco Eventos + Agenda + Operação

## Objetivo

Transformar um contrato comercial em trabalho operacional sem criar outro cadastro do zero.

`Contrato ativo → Evento → Operações → Agenda / Hoje`

## Evento

Cada contrato gera no máximo um evento operacional. O evento herda cliente, tipo, data e endereço do snapshot contratual. A equipe pode complementar local, horários, responsável e observações sem alterar o documento comercial.

## Operações

Retirada, entrega, montagem, desmontagem, devolução e conferência são registros independentes vinculados ao evento. Isso permite que uma empresa trabalhe apenas com retirada, outra ofereça montagem e outra combine várias modalidades no mesmo evento.

Não existe uma regra global da Heaven obrigando um fluxo logístico específico.

## Tarefas

A tabela `tasks` representa trabalho humano acionável. Pode estar ligada a evento ou lead e possui responsável, prazo, prioridade e ação. Isso evita transformar a tela Hoje em um conjunto de regras hardcoded.

## Hoje

A view `today_actions` unifica tarefas e operações pendentes. A Home consulta essa fila e mostra apenas o que exige ação. CRM, Agenda, Produção e Logística continuam sendo as telas de contexto completo.

## Agenda

A agenda usa `events.starts_at` para eventos e `event_operations.scheduled_at` para compromissos operacionais. A mesma estrutura suportará visão diária, semanal e mensal.

## Próximo bloco

**Estoque + reservas por data + conflito de disponibilidade + separação/devolução.** O estoque será configurável por tenant e o vínculo operacional será feito com Evento/Contrato, nunca com constantes específicas de uma decoradora.
