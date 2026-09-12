-- HEAVEN PLATAFORMA — GESTÃO / DASHBOARD
-- Indicadores derivados das tabelas transacionais. Nenhum KPI é mantido manualmente.

-- Vendas: orçamento aprovado na data de aprovação.
create or replace view public.management_sales with(security_invoker=true) as
select q.company_id,q.id as quote_id,q.client_id,q.lead_id,q.approved_at::date as sale_date,q.total,
 q.event_date,q.event_type
from public.quotes q
where q.status='aprovado' and q.approved_at is not null;
grant select on public.management_sales to authenticated;

-- Eventos/entregas: receita comercial associada aos eventos que acontecem no período.
create or replace view public.management_events with(security_invoker=true) as
select e.company_id,e.id as event_id,e.contract_id,e.client_id,e.starts_at,e.status,e.event_type,e.city,
 coalesce((ct.commercial_snapshot->>'total')::numeric,0) as contract_total
from public.events e
join public.contracts ct on ct.id=e.contract_id and ct.company_id=e.company_id
where e.status <> 'cancelado';
grant select on public.management_events to authenticated;

-- Pipeline CRM por etapa.
create or replace view public.management_crm_funnel with(security_invoker=true) as
select l.company_id,l.status,count(*)::bigint as lead_count
from public.leads l
group by l.company_id,l.status;
grant select on public.management_crm_funnel to authenticated;

-- Financeiro em aberto, sem confundir títulos com caixa realizado.
create or replace view public.management_open_finance with(security_invoker=true) as
select e.company_id,e.direction,e.status,e.due_date,
 sum(e.open_amount)::numeric(14,2) as open_amount,
 count(*)::bigint as entry_count
from public.financial_entry_balances e
where e.status not in ('pago','cancelado') and e.open_amount>0
group by e.company_id,e.direction,e.status,e.due_date;
grant select on public.management_open_finance to authenticated;

-- Função consolidada para dashboard mensal/anual.
create or replace function public.management_summary(target_company_id uuid,period_from date,period_until date)
returns jsonb
language plpgsql
stable
security invoker
set search_path=''
as $$
declare
 sales_total numeric:=0; sales_count bigint:=0; event_total numeric:=0; event_count bigint:=0;
 received numeric:=0; paid numeric:=0; operating_cash numeric:=0; overdue_receivable numeric:=0;
 leads_count bigint:=0; won_count bigint:=0; avg_ticket numeric:=0;
begin
 if period_until < period_from then raise exception 'Período inválido'; end if;
 if not private.is_company_member(target_company_id) then raise exception 'Empresa não autorizada'; end if;

 select coalesce(sum(s.total),0),count(*) into sales_total,sales_count
 from public.management_sales s where s.company_id=target_company_id and s.sale_date between period_from and period_until;

 select coalesce(sum(e.contract_total),0),count(*) into event_total,event_count
 from public.management_events e where e.company_id=target_company_id and e.starts_at::date between period_from and period_until;

 select coalesce(sum(case when c.direction='receber' then c.amount else 0 end),0),
        coalesce(sum(case when c.direction='pagar' then c.amount else 0 end),0),
        coalesce(sum(c.operating_amount),0)
 into received,paid,operating_cash
 from public.cash_movements c where c.company_id=target_company_id and c.paid_at::date between period_from and period_until;

 select coalesce(sum(f.open_amount),0) into overdue_receivable
 from public.financial_entry_balances f
 where f.company_id=target_company_id and f.direction='receber' and f.status not in ('pago','cancelado')
   and f.due_date < current_date and f.open_amount>0;

 select count(*),count(*) filter(where l.status='ganho') into leads_count,won_count
 from public.leads l where l.company_id=target_company_id and l.created_at::date between period_from and period_until;

 avg_ticket:=case when sales_count>0 then sales_total/sales_count else 0 end;
 return jsonb_build_object(
  'sales_total',sales_total,'sales_count',sales_count,'average_ticket',round(avg_ticket,2),
  'event_total',event_total,'event_count',event_count,
  'received',received,'paid',paid,'operating_cash',operating_cash,
  'overdue_receivable',overdue_receivable,
  'leads_count',leads_count,'won_count',won_count,
  'conversion_rate',case when leads_count>0 then round((won_count::numeric/leads_count::numeric)*100,2) else 0 end
 );
end;
$$;
grant execute on function public.management_summary(uuid,date,date) to authenticated;

-- Pendências relevantes para gestão. Não substitui a fila operacional Hoje.
create or replace view public.management_alerts with(security_invoker=true) as
select f.company_id,'finance_overdue'::text as alert_type,f.id as source_id,
 ('Recebimento vencido: '||f.description)::text as title,f.due_date::timestamptz as reference_at,
 jsonb_build_object('open_amount',f.open_amount,'contract_id',f.contract_id,'client_id',f.client_id) as payload
from public.financial_entry_balances f
where f.direction='receber' and f.status not in ('pago','cancelado') and f.due_date<current_date and f.open_amount>0
union all
select c.company_id,'inventory_conflict',c.item_id,
 ('Conflito de estoque: '||c.item_name),c.reserved_from,
 jsonb_build_object('event_id',c.event_id,'quantity',c.quantity,'available',c.available_excluding_event)
from public.inventory_conflicts c;
grant select on public.management_alerts to authenticated;
