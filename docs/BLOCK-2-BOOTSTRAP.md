# Bloco 2 — Bootstrap independente

## Objetivo

Transformar o protótipo exportado em uma aplicação Heaven Plataforma independente, preservando os módulos úteis e removendo acoplamentos com a ferramenta de prototipação.

## Auditoria da base recebida

A base contém aproximadamente 150 arquivos de aplicação entre `src`, `supabase` e `public`, incluindo Dashboard, Leads, Clientes, Contratos, Agenda, Produção, Solicitações, Financeiro, Administração Heaven, onboarding de empresa, integração Supabase e testes de segurança/multiempresa.

## Alterações do bootstrap

- pacote renomeado para `heaven-plataforma`;
- configuração Vite/TanStack oficial, sem plugin estrutural do Lovable;
- dependências `@lovable.dev/*` removidas do manifesto da aplicação;
- configuração Bun limpa de exceções específicas do Lovable;
- `.env` real permanece fora do repositório;
- `.env.example` contém somente placeholders;
- stack mantida em React + TanStack Start + TypeScript + Tailwind + Supabase;
- scripts de `typecheck` e `test` definidos para validação contínua.

## Importação modular

A importação será feita em grupos funcionais para que cada etapa possa ser validada antes de integrar o próximo conjunto:

1. shell, autenticação e Supabase;
2. Dashboard e operação de hoje;
3. CRM, Leads e Clientes;
4. Orçamentos e Contratos;
5. Agenda, Produção e Logística;
6. Financeiro e Gestão;
7. Configurações de empresa, Kits e Regras;
8. Administração SaaS.

## Regra de migração

Código reaproveitado do protótipo deve passar por revisão multiempresa. Nenhum filtro visual substitui RLS no banco, e nenhuma regra específica da LHL será convertida em constante global da Heaven.
