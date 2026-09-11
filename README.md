# Heaven Plataforma

ERP SaaS multiempresa para empresas de decoração e locação de festas.

A Heaven Plataforma nasce a partir dos fluxos operacionais validados no Sistema LHL Festas, porém com arquitetura independente e configurável por empresa.

## Visão do produto

Lead → Cliente → Orçamento → Contrato → Agenda/Evento → Operação → Estoque/Compras → Financeiro → Gestão.

## Princípios

- Multiempresa desde a fundação (tenant isolation)
- Configurável para diferentes decoradoras
- Nenhuma regra comercial específica da LHL fixa no código
- Operação orientada por tarefas e alertas
- CRM e WhatsApp como parte central do fluxo comercial
- Contratos e documentos integrados
- Estoque baseado em reservas por evento
- Financeiro conectado aos contratos e eventos
- Dashboard operacional e gerencial
- Base preparada para planos SaaS e cobrança recorrente

## Stack

- React 19
- TanStack Start / Router / Query
- Vite
- Tailwind CSS
- Supabase (Postgres, Auth e RLS)
- TypeScript

## Desenvolvimento

A branch `main` é a base estável. A branch `develop` recebe os blocos de desenvolvimento antes da publicação.

Variáveis reais de ambiente nunca devem ser versionadas. Use `.env.example` como referência.

## Migração do protótipo

A base exportada do protótipo está sendo migrada sem dependência estrutural do Lovable. O objetivo é preservar os módulos úteis já construídos e substituir regras específicas por serviços e configurações multiempresa.

## Status

🚧 Bloco 2 — bootstrap independente da aplicação e importação modular da base em andamento.
