-- ============================================================
-- Rode no SQL Editor do Supabase ANTES de publicar esta versão.
-- Não tive acesso ao seu schema: confira os nomes (tabela
-- "inscricoes", colunas "id", "valor", "status") e ajuste se preciso.
-- ============================================================

-- 1) Descobrir se há CHECK limitando o valor a 40/50/60
--    (se aparecer algo com "valor", remova-o ou inclua o 0):
select conrelid::regclass as tabela, conname, pg_get_constraintdef(oid) as regra
from pg_constraint
where contype = 'c' and pg_get_constraintdef(oid) ilike '%valor%';

-- Exemplo para remover (troque pelos nomes que apareceram acima):
-- alter table public.participantes drop constraint nome_da_regra;
-- alter table public.inscricoes    drop constraint nome_da_regra;

-- 2) Coluna e função chamadas pelo botão "Confirmar inscrição"
alter table public.inscricoes
  add column if not exists autorizacao_confirmada_em timestamptz;

create or replace function public.confirmar_inscricao(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.inscricoes
     set autorizacao_confirmada_em = now(),
         -- Gratuito não tem pagamento para conferir: já fica confirmado.
         -- Pago continua "pendente" até a organização conferir o comprovante.
         status = case when valor = 0 then 'confirmado' else status end
   where id = p_id;

  if not found then
    raise exception 'inscricao_nao_encontrada';
  end if;
end $$;

grant execute on function public.confirmar_inscricao(uuid) to anon;
