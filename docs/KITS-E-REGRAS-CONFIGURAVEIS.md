# Heaven Plataforma — Kits e Regras Configuráveis

## Princípio

A Heaven Plataforma é multiempresa. Nenhum kit, modalidade, preço, caução, percentual de sinal, prazo ou regra operacional da LHL deve ficar fixo no produto.

Cada empresa cadastrada terá uma área própria para configurar seu modelo de negócio. A LHL serve como referência de fluxo e validação, não como regra global.

## Área sugerida no ERP

Configurações > Meu Negócio

Subáreas:

1. Modalidades e Serviços
2. Kits e Planos
3. Regras Comerciais
4. Regras de Pagamento
5. Caução e Garantias
6. Retirada, Entrega e Devolução
7. Montagem e Desmontagem
8. Contratos e Termos
9. Campos e opções personalizadas

## Modalidades e Serviços

A empresa poderá criar livremente modalidades como Peg & Monte, Festa na Mesa, Decoração Completa, Locação de Peças, Montagem, Personalizados ou qualquer outra modalidade própria.

Campos básicos:
- nome
- descrição
- ativo/inativo
- ordem de exibição
- exige retirada?
- exige devolução?
- possui montagem?
- possui desmontagem?
- permite entrega?

## Kits e Planos

Cada empresa poderá cadastrar quantos kits desejar.

Cada kit deverá ter:
- empresa/tenant
- modalidade vinculada
- nome
- descrição comercial
- preço sugerido opcional
- permitir preço manual
- ativo/inativo
- ordem de exibição
- imagem opcional
- itens inclusos
- quantidades
- observações internas
- observações para cliente
- regras específicas opcionais

O sistema não deve pressupor nomes como Essencial, Completo ou Premium. Esses nomes pertencem à empresa que os cadastrar.

## Itens dos kits

O kit poderá ser composto por itens do estoque ou por itens descritivos sem controle físico.

Quando ligado ao estoque, a contratação do kit deve gerar necessidade/reserva das respectivas quantidades para a data do evento.

Exemplo conceitual:
Kit -> componentes -> item de estoque -> quantidade.

Isso evita cadastrar novamente no contrato aquilo que já está definido no kit, mas permite ajustes por evento.

## Regras Comerciais

Cada empresa poderá definir padrões como:
- percentual ou valor padrão de sinal
- permitir negociação manual do sinal
- quando a reserva é considerada confirmada
- prazo para pagamento final
- política de cancelamento
- multa por atraso
- desconto permitido
- validade padrão de orçamento
- política para cliente recorrente

Todas as regras devem poder ser sobrescritas em um orçamento/contrato específico por usuário autorizado, quando a empresa permitir.

## Caução e Garantias

A empresa poderá escolher:
- não trabalhar com caução
- caução fixa
- caução por modalidade
- caução por kit
- caução calculada manualmente

Também poderá definir quando a caução é cobrada, quando é devolvida e quais condições podem gerar retenção parcial ou total.

## Logística

Configurações independentes para:
- retirada pelo cliente
- devolução pelo cliente
- entrega pela empresa
- retirada pela empresa
- transportadora/parceiro
- montagem no local
- desmontagem no local

A empresa poderá habilitar apenas os fluxos que realmente utiliza.

## Contratos

As regras configuradas deverão alimentar a geração do contrato, mas o contrato deve salvar uma fotografia das condições negociadas naquele momento.

Alterar uma regra da empresa no futuro não pode alterar contratos antigos.

## Arquitetura de dados

Todas as entidades devem possuir company_id/tenant_id e respeitar isolamento por empresa.

Entidades conceituais principais:
- companies
- business_modalities
- service_packages
- service_package_items
- business_rules
- payment_rules
- deposit_rules
- logistics_rules
- contract_templates
- custom_fields

Regras devem preferencialmente ser estruturadas em colunas/tabelas quando forem essenciais para cálculos e automações. JSON configurável pode ser usado para extensões, mas não deve substituir modelagem relacional dos dados centrais.

## Herança de regras

Prioridade sugerida:

Regra específica do contrato > regra específica do kit > regra da modalidade > regra padrão da empresa.

O sistema deve sempre registrar qual valor efetivamente foi aplicado ao contrato.

## UX

O onboarding inicial deve permitir que uma decoradora comece de forma simples, sem exigir configuração avançada.

Fluxo inicial sugerido:
1. cadastrar empresa
2. escolher tipos de serviço
3. criar primeiro kit
4. definir sinal/pagamento
5. definir logística
6. definir caução, se utilizar
7. começar a operar

Configurações avançadas permanecem disponíveis posteriormente.

## Referência LHL

A LHL poderá ser usada como tenant piloto para validar modalidades, kits, sinal, caução, retirada/devolução, montagem, contratos e estoque. Esses dados devem ser cadastrados como dados da empresa LHL, nunca como constantes globais da Heaven Plataforma.
