# Bloco 2 — Onboarding, equipe e isolamento multiempresa

## Objetivo

Transformar o shell autenticado da Heaven em uma fundação SaaS segura: o usuário entra, pertence a uma ou mais empresas por `company_members`, trabalha dentro de um contexto de empresa e nunca recebe dados de outro tenant por confiar apenas no frontend.

## Papéis

- **Proprietário**: controle total da empresa e, futuramente, assinatura/plano.
- **Administrador**: gestão da empresa e da equipe.
- **Gerente**: operação completa e configurações do negócio, sem administração crítica da conta.
- **Equipe**: uso operacional conforme módulos liberados.

A interface pode esconder ações, mas a autorização definitiva deve acontecer no banco por grants, RLS e RPCs.

## Onboarding

`create_company_with_owner` cria a empresa e o vínculo do usuário como proprietário na mesma transação. Isso evita empresa criada sem dono ou vínculo parcial por falha entre duas chamadas do navegador.

O formulário inicial coleta somente o essencial. Modalidades, kits, regras comerciais, caução, logística e contratos entram depois em **Configurações > Meu Negócio**.

## Segurança

As funções auxiliares de autorização ficam no schema `private`, usam `security definer` com `search_path` vazio e não ficam expostas para `anon`.

As tabelas continuam com RLS. Membros ativos podem ler dados da própria empresa; alterações administrativas exigem papéis compatíveis. O cliente nunca deve receber `service_role`.

## Próxima validação antes de produção

Este SQL continua sendo blueprint versionado. Antes de aplicar em produção precisamos conectar um projeto Supabase de desenvolvimento, reconciliar as migrations originais do protótipo Lovable, executar o SQL de forma controlada e rodar os advisors de segurança/performance.

## Próximo passo funcional

Com a fundação de identidade pronta, a sequência é conectar o primeiro fluxo que gera valor diário:

**Lead → tarefa em Hoje → atendimento/WhatsApp → orçamento → cliente → contrato.**
