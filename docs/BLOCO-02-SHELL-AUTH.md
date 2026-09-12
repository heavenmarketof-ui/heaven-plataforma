# Bloco 02 — Shell, autenticação e contexto da empresa

## Objetivo

Transformar a base visual em uma aplicação SaaS que sempre saiba duas coisas antes de carregar dados operacionais: quem é o usuário autenticado e qual empresa ele está autorizado a acessar.

## Implementado nesta etapa

- cliente Supabase sem segredos no código;
- restauração de sessão e atualização de autenticação;
- resolução do vínculo `auth.users -> company_members -> companies`;
- contexto tipado da empresa ativa e papel do usuário;
- shell inicial Heaven com navegação dos módulos do produto;
- estado seguro para usuário autenticado sem empresa vinculada;
- nenhuma regra comercial da LHL foi fixada no shell.

## Regra obrigatória para os próximos módulos

Toda consulta de negócio deverá ser protegida no banco por RLS e escopo de `company_id`. O filtro no frontend melhora UX, mas não substitui isolamento no PostgreSQL.

## Próxima etapa

Consolidar onboarding, papéis/permissões e políticas RLS antes de conectar CRM, contratos, estoque e financeiro a dados reais.
