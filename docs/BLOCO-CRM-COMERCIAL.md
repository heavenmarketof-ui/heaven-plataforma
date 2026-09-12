# Bloco CRM Comercial — Lead → Orçamento → Cliente

## Princípio

O usuário não deve redigitar informações já capturadas. O lead é a origem comercial; orçamento e cliente reutilizam esses dados e acrescentam apenas o que nasce em cada etapa.

## CRM

O funil inicial possui seis estados essenciais: Novo, Em atendimento, Orçamento, Negociação, Ganho e Perdido. A visualização Kanban é uma interface para trabalhar o funil; o estado permanece persistido no banco e protegido por tenant.

## Orçamento

Um orçamento criado a partir de um lead herda empresa, responsável, tipo/data/cidade do evento e vínculo com o lead. Seus itens são flexíveis e podem representar item, kit, serviço, montagem, transporte, adicional ou outro. Nenhum catálogo ou preço específico de uma empresa é hardcoded.

## Cliente

A conversão cria o cliente reaproveitando nome, telefone, e-mail, cidade e observações. A origem (`source_lead_id`) é preservada para rastreabilidade e evita conversão duplicada do mesmo lead.

## Histórico

`lead_activities` registra eventos comerciais importantes. A intenção é que contato, notas, mudanças de etapa, tarefas, orçamentos e conversões formem uma linha do tempo única do relacionamento.

## Regra para o próximo bloco

Contrato não deve recriar cliente nem orçamento. O contrato nascerá de um orçamento aprovado, herdará os dados necessários e congelará um snapshot comercial para que alterações futuras no cadastro não reescrevam um documento já negociado.
