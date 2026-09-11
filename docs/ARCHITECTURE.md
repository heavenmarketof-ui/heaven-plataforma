# Arquitetura inicial — Heaven Plataforma

## Modelo
SaaS multi-tenant. Cada registro de negócio deve pertencer explicitamente a uma organização/tenant e o isolamento deve ser aplicado também no banco, preferencialmente com RLS.

## Entidades de fundação
- organizations
- organization_members
- profiles
- roles / permissions
- leads
- customers
- quotes / quote_items
- contracts
- events
- tasks
- inventory_items
- inventory_reservations
- logistics
- financial_transactions
- document_templates
- audit_logs
- subscriptions / plans

## Segurança
- Nunca confiar apenas em filtro do frontend para tenant isolation.
- Toda operação deve validar organização e permissão no backend/banco.
- Credenciais e chaves somente em variáveis de ambiente.
- `.env` real nunca deve ser versionado.
- Logs de auditoria para ações críticas.

## Estratégia de branches
- `main`: versão estável/publicável.
- `develop`: integração da construção atual.
- features: branches curtas por bloco de trabalho.

## Estratégia de migração da base Lovable
1. Importar somente código necessário; não versionar `.env` nem metadados do projeto Lovable.
2. Remover dependências específicas do Lovable quando não forem necessárias em runtime.
3. Auditar schema e RLS antes de conectar dados reais.
4. Substituir mocks e regras específicas por serviços multi-tenant.
5. Implementar os módulos em blocos testáveis.

## Regra de produto
A Heaven não deve conhecer `LHL` como regra de domínio. Kits, caução, percentuais, status, textos de contrato, categorias, serviços e demais políticas precisam ser configuráveis por organização.
