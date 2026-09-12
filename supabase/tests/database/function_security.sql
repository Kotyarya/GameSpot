-- TASK-6 regression checks. Run after migrations with:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/database/function_security.sql

do $$
declare
  unsecured_functions text;
begin
  select string_agg(
    format('%I.%I(%s)', namespace.nspname, function_name.proname,
      pg_get_function_identity_arguments(function_name.oid)),
    E'\n'
    order by function_name.proname
  )
  into unsecured_functions
  from pg_proc function_name
  join pg_namespace namespace
    on namespace.oid = function_name.pronamespace
  where namespace.nspname = 'public'
    and function_name.prokind = 'f'
    and not coalesce(
      function_name.proconfig @> array['search_path=public, pg_temp']::text[]
      or function_name.proconfig @> array['search_path=pg_catalog']::text[],
      false
    );

  if unsecured_functions is not null then
    raise exception 'public functions without a trusted search_path:%',
      E'\n' || unsecured_functions;
  end if;
end;
$$;
