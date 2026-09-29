-- TASK-6: Supabase creates this event-trigger helper in some hosted projects.
-- It runs as its postgres owner when the event trigger fires and must not be
-- exposed as a Data API RPC to client roles. Local environments where the
-- platform helper is absent intentionally treat this migration as a no-op.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute
      'revoke execute on function public.rls_auto_enable() '
      'from public, anon, authenticated';
  end if;
end;
$$;
