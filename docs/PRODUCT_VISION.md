# Heaven Plataforma — Visão do Produto

## Objetivo
Transformar a experiência operacional validada no Sistema LHL em um ERP SaaS comercial para decoradoras, locadoras e empresas de festas.

## Fluxo principal
Aquisição → Lead → Atendimento → Orçamento → Cliente → Contrato → Pagamento → Reserva de itens → Agenda → Separação → Retirada/Entrega → Montagem → Devolução → Conferência → Fechamento financeiro → Pós-venda.

## Módulos de referência

### 1. Hoje / Operação
Tela inicial acionável. Deve mostrar novos leads, eventos próximos, tarefas, pagamentos pendentes, retiradas, entregas, devoluções, conflitos de estoque e demais pendências. Cards devem levar diretamente à ação, incluindo contato por WhatsApp quando aplicável.

### 2. CRM e Leads
Entrada de leads, origem, funil, responsável, histórico, próxima ação, conversão em cliente/orçamento e alertas de lead novo.

### 3. Clientes
Cadastro completo, histórico de eventos, contratos, pagamentos, recorrência, observações e documentos.

### 4. Orçamentos
Composição flexível por itens, kits, serviços, montagem, transporte, adicionais, descontos e condições comerciais. Valores e regras pertencem a cada empresa/tenant.

### 5. Contratos
Templates configuráveis, cláusulas, dados do evento, condições de pagamento, caução quando aplicável, ciência do cliente, geração de PDF e status.

### 6. Agenda e Eventos
Calendário operacional com evento, retirada, entrega, montagem e devolução. Visualização diária, semanal e mensal.

### 7. Estoque
Itens, categorias, quantidades, disponibilidade por data, reservas vinculadas a eventos, manutenção, avarias, perdas e checklist de separação/devolução.

### 8. Logística
Retirada pelo cliente, entrega, montagem, desmontagem, endereço, horários, responsável, custos e status.

### 9. Financeiro
Receitas e despesas ligadas a contratos/eventos, sinal, saldo, caução configurável, contas a receber/pagar, fluxo de caixa e competência/caixa.

### 10. Gestão
Vendas do período, entregas/eventos realizados, ticket médio, entradas/saídas, conversão de leads, receita, custos, margem e visão anual.

### 11. Configurações da Empresa
Identidade, dados fiscais, usuários, permissões, catálogo, kits, regras comerciais, formas de pagamento, documentos, templates, regiões e parâmetros operacionais.

### 12. Administração SaaS
Tenants, planos, limites, assinaturas, feature flags, suporte, auditoria e métricas da plataforma.

## Regra arquitetural principal
Tudo que hoje é uma particularidade da LHL deve virar configuração da empresa, nunca constante global da Heaven. A LHL será tenant de referência e ambiente de validação do produto, não a regra do produto.
