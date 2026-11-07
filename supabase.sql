-- Cole no SQL Editor do Supabase e clique em Run. Pode rodar de novo sem perder dados.
-- ANTES DE RODAR: troque TROQUE-ESTA-SENHA por uma senha longa (é a senha do admin.html).
create extension if not exists unaccent with schema extensions;

create table if not exists config (chave text primary key, valor text not null);
insert into config values ('admin_senha', 'TROQUE-ESTA-SENHA') on conflict do nothing;

create table if not exists participantes (
  id bigint generated always as identity primary key,
  nome text not null,
  valor int not null check (valor in (40,50,60))
);
alter table participantes add column if not exists nascimento date;
alter table participantes add column if not exists cpf text;
alter table participantes add column if not exists telefone text;
alter table participantes add column if not exists responsavel text;
alter table participantes add column if not exists responsavel_cpf text;
alter table participantes add column if not exists responsavel_telefone text;

create table if not exists inscricoes (
  id uuid primary key,
  nome text not null,
  valor int not null,
  na_lista boolean not null default false,
  criado_em timestamptz not null default now()
);
alter table inscricoes add column if not exists nascimento date;
alter table inscricoes add column if not exists cpf text;
alter table inscricoes add column if not exists telefone text;
alter table inscricoes add column if not exists responsavel text;
alter table inscricoes add column if not exists responsavel_cpf text;
alter table inscricoes add column if not exists responsavel_telefone text;
alter table inscricoes add column if not exists comprovante_url text;
alter table inscricoes add column if not exists status text not null default 'pendente';
create unique index if not exists inscricoes_cpf_uk on inscricoes(cpf);

-- RLS ligado e sem políticas: o site só acessa os dados pelas funções abaixo.
alter table config enable row level security;
alter table participantes enable row level security;
alter table inscricoes enable row level security;

create or replace function normaliza(t text) returns text language sql stable
set search_path = public, extensions as
$$ select regexp_replace(lower(unaccent(trim(t))), '\s+', ' ', 'g') $$;
create or replace function so_digitos(t text) returns text language sql immutable as
$$ select regexp_replace(coalesce(t, ''), '\D', '', 'g') $$;
create or replace function admin_ok(p text) returns void language plpgsql security definer set search_path = public as
$$ begin
  if p is distinct from (select valor from config where chave = 'admin_senha') then raise exception 'senha_invalida'; end if;
end $$;

-- ===== Formulário público =====
drop function if exists buscar_valor(text);
drop function if exists registrar_inscricao(uuid, text, date, text, text, text, text);
drop function if exists registrar_inscricao(uuid, text, date, text, text, text);
-- Devolve modalidade e dados pré-preenchidos (CPFs nunca são devolvidos; a pessoa digita e o servidor confere).
create or replace function buscar_participante(p_nome text) returns jsonb
language sql security definer set search_path = public, extensions as
$$ select to_jsonb(x) from (
     select valor, nascimento, telefone, responsavel, responsavel_telefone, (cpf is not null) as tem_cpf
     from participantes where normaliza(nome) = normaliza(p_nome) limit 1) x $$;

create or replace function registrar_inscricao(p_id uuid, p_nome text, p_nascimento date, p_cpf text,
  p_telefone text, p_responsavel text, p_responsavel_cpf text, p_responsavel_telefone text)
returns jsonb language plpgsql security definer set search_path = public, extensions as
$$
declare
  pr participantes%rowtype; ex inscricoes%rowtype; tem boolean; v int;
  v_cpf text := so_digitos(p_cpf);
  v_rcpf text := nullif(so_digitos(p_responsavel_cpf), '');
  menor boolean := p_nascimento > (current_date - interval '18 years');
begin
  if length(v_cpf) <> 11 or length(trim(p_nome)) < 5 then raise exception 'dados_invalidos'; end if;
  select * into pr from participantes where normaliza(nome) = normaliza(p_nome) limit 1;
  tem := found;
  if tem and pr.cpf is not null and so_digitos(pr.cpf) <> v_cpf then raise exception 'cpf_nao_confere'; end if;
  v := case when tem then pr.valor else 60 end;
  if menor then
    if v_rcpf is null or length(v_rcpf) <> 11 or coalesce(trim(p_responsavel), '') = '' then raise exception 'responsavel_obrigatorio'; end if;
    if v_rcpf = v_cpf then raise exception 'cpf_igual'; end if;
    -- CPF de menor não pode já ter sido usado como responsável em outra inscrição
    if exists (select 1 from inscricoes where responsavel_cpf = v_cpf) then raise exception 'cpf_menor_responsavel'; end if;
    -- responsável não pode ser um menor já inscrito
    if exists (select 1 from inscricoes where cpf = v_rcpf and nascimento > current_date - interval '18 years') then raise exception 'responsavel_menor'; end if;
  else
    v_rcpf := null;
  end if;
  select * into ex from inscricoes where cpf = v_cpf;
  if found then
    -- mesma pessoa que parou antes de enviar o comprovante: retoma a inscrição
    if ex.comprovante_url is null and normaliza(ex.nome) = normaliza(p_nome) then
      update inscricoes set nascimento = p_nascimento, telefone = p_telefone, valor = v, na_lista = tem,
        responsavel = case when menor then p_responsavel end, responsavel_cpf = v_rcpf,
        responsavel_telefone = case when menor then p_responsavel_telefone end
      where id = ex.id;
      return jsonb_build_object('id', ex.id, 'valor', v);
    end if;
    raise exception 'cpf_duplicado';
  end if;
  insert into inscricoes(id, nome, valor, na_lista, nascimento, cpf, telefone, responsavel, responsavel_cpf, responsavel_telefone)
  values (p_id, trim(p_nome), v, tem, p_nascimento, v_cpf, p_telefone,
    case when menor then p_responsavel end, v_rcpf, case when menor then p_responsavel_telefone end);
  return jsonb_build_object('id', p_id, 'valor', v);
end $$;

create or replace function salvar_comprovante(p_id uuid, p_url text) returns void
language sql security definer set search_path = public as
$$ update inscricoes set comprovante_url = p_url where id = p_id and comprovante_url is null $$;

-- ===== Admin (protegido pela senha da tabela config) =====
create or replace function admin_listar(p_senha text) returns jsonb
language plpgsql security definer set search_path = public as
$$ begin
  perform admin_ok(p_senha);
  return jsonb_build_object(
    'participantes', (select coalesce(jsonb_agg(to_jsonb(p) order by p.nome), '[]') from participantes p),
    'inscricoes', (select coalesce(jsonb_agg(to_jsonb(i) order by i.criado_em desc), '[]') from inscricoes i));
end $$;

create or replace function admin_salvar_participante(p_senha text, p_id bigint, p_dados jsonb) returns void
language plpgsql security definer set search_path = public as
$$ begin
  perform admin_ok(p_senha);
  if p_id is null then
    insert into participantes(nome, valor, nascimento, cpf, telefone, responsavel, responsavel_cpf, responsavel_telefone)
    values (trim(p_dados->>'nome'), (p_dados->>'valor')::int, nullif(p_dados->>'nascimento', '')::date,
      nullif(so_digitos(p_dados->>'cpf'), ''), nullif(p_dados->>'telefone', ''), nullif(p_dados->>'responsavel', ''),
      nullif(so_digitos(p_dados->>'responsavel_cpf'), ''), nullif(p_dados->>'responsavel_telefone', ''));
  else
    update participantes set nome = trim(p_dados->>'nome'), valor = (p_dados->>'valor')::int,
      nascimento = nullif(p_dados->>'nascimento', '')::date, cpf = nullif(so_digitos(p_dados->>'cpf'), ''),
      telefone = nullif(p_dados->>'telefone', ''), responsavel = nullif(p_dados->>'responsavel', ''),
      responsavel_cpf = nullif(so_digitos(p_dados->>'responsavel_cpf'), ''),
      responsavel_telefone = nullif(p_dados->>'responsavel_telefone', '')
    where id = p_id;
  end if;
end $$;

create or replace function admin_importar(p_senha text, p_lista jsonb) returns int
language plpgsql security definer set search_path = public, extensions as
$$ declare n int; begin
  perform admin_ok(p_senha);
  insert into participantes(nome, valor)
  select trim(x->>'nome'), (x->>'valor')::int from jsonb_array_elements(p_lista) x
  where not exists (select 1 from participantes p where normaliza(p.nome) = normaliza(x->>'nome'));
  get diagnostics n = row_count;
  return n;
end $$;

create or replace function admin_excluir_participante(p_senha text, p_id bigint) returns void
language plpgsql security definer set search_path = public as
$$ begin perform admin_ok(p_senha); delete from participantes where id = p_id; end $$;
create or replace function admin_status(p_senha text, p_id uuid, p_status text) returns void
language plpgsql security definer set search_path = public as
$$ begin perform admin_ok(p_senha); update inscricoes set status = p_status where id = p_id and p_status in ('pendente', 'confirmado'); end $$;
create or replace function admin_excluir_inscricao(p_senha text, p_id uuid) returns void
language plpgsql security definer set search_path = public as
$$ begin perform admin_ok(p_senha); delete from inscricoes where id = p_id; end $$;

revoke execute on function admin_ok, normaliza, so_digitos from public, anon, authenticated;
grant execute on function buscar_participante, registrar_inscricao, salvar_comprovante, admin_listar,
  admin_salvar_participante, admin_importar, admin_excluir_participante, admin_status, admin_excluir_inscricao to anon;
