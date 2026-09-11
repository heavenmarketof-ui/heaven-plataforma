# Bloco 01 — Fundação Heaven Plataforma

## Objetivo

Transformar a base experimental em um produto SaaS independente, multiempresa e preparado para receber os fluxos validados na operação real da LHL sem acoplar o produto às regras da LHL.

## Decisões deste bloco

- `main` permanece estável; desenvolvimento ocorre em `develop`.
- Segredos do `.env` original não serão copiados para o repositório.
- Lovable não será a fonte de verdade do produto.
- Supabase/Postgres será a base proposta para autenticação, isolamento multiempresa e dados relacionais.
- Toda entidade de negócio deverá possuir vínculo explícito com `company_id`.
- A LHL será tenant piloto/dados de referência, não configuração global.
- Kits, modalidades, preços, sinal, caução e logística serão configuráveis por empresa.
- O sistema deverá preservar snapshot das condições negociadas em cada contrato.

## Núcleo de identidade

Relação principal:

`auth.users -> profiles -> company_members -> companies`

Um usuário acessa dados de uma empresa apenas por associação autorizada em `company_members` (ou por função administrativa da própria plataforma).

## Núcleo configurável da decoradora

Relação inicial:

`companies -> business_modalities -> service_packages -> business_rules`

Exemplos de modalidades que uma empresa pode criar: Peg & Monte, Decoração Completa, Festa na Mesa, Locação, Personalizados. A Heaven não presume nenhuma delas.

## Hierarquia de regras

1. condição salva no contrato
2. regra específica do kit
3. regra específica da modalidade
4. regra padrão da empresa

A condição efetivamente aplicada deve ser persistida no contrato para garantir histórico.

## Próximos blocos

Bloco 02: importar a aplicação visual e componentes úteis da base recebida, removendo telemetria/metadados do Lovable e preparando build independente.

Bloco 03: autenticação, onboarding da empresa, usuários, papéis e RLS validado.

Bloco 04: tela `Meu Negócio` para modalidades, kits e regras.

Bloco 05: CRM e fluxo Lead -> Cliente -> Orçamento -> Contrato.

## Critério de pronto do Bloco 01

A arquitetura central deve estar documentada, versionada e sem segredos. Nenhuma decisão do banco pode pressupor que todas as decoradoras trabalham como a LHL.
