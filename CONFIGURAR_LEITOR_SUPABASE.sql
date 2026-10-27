-- Execute no SQL Editor do projeto Supabase usado no cadastro.
-- Não apaga registros. Requer public.participants com name, cpf, qr_token,
-- created_at, presence_confirmed e presence_at.
-- Os visitantes NÃO recebem acesso público à lista de CPFs.
create or replace function public.event_lookup_qr(p_token text)
returns table(name text, cpf_masked text, created_at timestamptz, presence_confirmed boolean, presence_at timestamptz)
language sql security definer set search_path = ''
as $$
  select p.name::text,
         ('***.***.***-' || right(p.cpf::text,2))::text,
         p.created_at::timestamptz,
         coalesce(p.presence_confirmed,false),
         p.presence_at::timestamptz
  from public.participants p
  where p.qr_token::text = p_token
  limit 1;
$$;
create or replace function public.event_confirm_qr(p_token text)
returns table(name text, cpf_masked text, created_at timestamptz, presence_confirmed boolean, presence_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
begin
  update public.participants p
  set presence_confirmed = true,
      presence_at = coalesce(p.presence_at,now())
  where p.qr_token::text = p_token and coalesce(p.presence_confirmed,false) = false;
  return query
    select p.name::text,
           ('***.***.***-' || right(p.cpf::text,2))::text,
           p.created_at::timestamptz,
           coalesce(p.presence_confirmed,false),
           p.presence_at::timestamptz
    from public.participants p
    where p.qr_token::text = p_token
    limit 1;
end;
$$;
revoke all on function public.event_lookup_qr(text) from public;
revoke all on function public.event_confirm_qr(text) from public;
grant execute on function public.event_lookup_qr(text) to anon, authenticated;
grant execute on function public.event_confirm_qr(text) to anon, authenticated;
