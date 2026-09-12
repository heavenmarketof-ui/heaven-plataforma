# Auditoria de Integração 01 — Heaven Plataforma

## Situação

A arquitetura funcional está coerente, mas o repositório ainda não deve ser tratado como aplicação pronta para produção. Os arquivos `database/001` a `010` são blueprints sequenciais e ainda não foram aplicados/testados em um projeto Supabase de desenvolvimento.

## Correções realizadas nesta auditoria

1. `company-context.ts` agora aceita tenants `trial` e `ativa`; o onboarding criava trial, mas o shell anteriormente procurava apenas empresa ativa.
2. `AuthenticatedApp` agora reidrata empresa após mudanças de autenticação e renderiza o `CompanyOnboardingForm` quando o usuário ainda não possui tenant.
3. Foi criado `preview/index.html`, totalmente independente de backend, para validar direção visual e navegação conceitual enquanto o bootstrap real é consolidado.

## Achados que bloqueiam CI/build confiável

### Frontend incompleto no repositório

O repositório atual contém componentes e libs do novo produto, mas ainda não contém todo o bootstrap necessário para afirmar que `npm run build` passa: router/entrypoints, estilos globais, configuração TypeScript completa e rotas finais precisam ser consolidados a partir da base original ou recriados de forma limpa.

### Dependências

O `package.json` atual é deliberadamente reduzido. Antes de importar componentes antigos da base Lovable, é necessário reconciliar as dependências realmente usadas e evitar restaurar dependências específicas do Lovable.

### Banco

Os SQLs novos formam uma arquitetura coerente entre si, porém não devem ser aplicados junto das migrations antigas da base Lovable sem reconciliação. É necessário escolher uma linha de schema canônica e executar os scripts em um Supabase de desenvolvimento vazio, corrigindo qualquer erro antes de produção.

### Segurança

A estrutura usa RLS, grants explícitos, `security_invoker` em views e funções privilegiadas com checagem de tenant. Ainda é obrigatório rodar os advisors do Supabase após aplicar o schema e testar isolamento com ao menos dois tenants reais de teste.

### Estados e transições

As principais transições estão modeladas: lead → orçamento → cliente → contrato → evento → reserva → produção → logística → devolução → financeiro. Próxima auditoria deve centralizar transições sensíveis em RPCs e reduzir updates diretos do frontend para impedir estados impossíveis.

## Plano de estabilização

1. Consolidar bootstrap React/TanStack independente do Lovable.
2. Criar rotas reais para Hoje, CRM, Clientes, Orçamentos, Contratos, Agenda, Estoque, Produção, Logística, Financeiro, Gestão e Configurações.
3. Reconciliar dependências e gerar lockfile limpo.
4. Aplicar schema em Supabase de desenvolvimento.
5. Gerar tipos Supabase do schema real.
6. Executar testes multi-tenant/RLS.
7. Só então ativar CI obrigatório com typecheck, testes e build.

## Regra

Não mascarar infraestrutura incompleta com um CI que apenas aparenta estar verde. O próximo ciclo técnico deve transformar os blueprints já construídos em aplicação executável e testável de ponta a ponta.
