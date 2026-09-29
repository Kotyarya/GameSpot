-- TASK-58: server-only cleanup used by the authenticated delete-account Edge Function.
-- The Edge Function derives p_user_id from its verified JWT; clients cannot execute this RPC.

create or replace function public.delete_user_data(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_reviewed_park_ids uuid[];
begin
  if p_user_id is null then
    raise exception 'User ID is required';
  end if;

  select array_agg(distinct pr.park_id)
  into v_reviewed_park_ids
  from public.park_reviews pr
  where pr.user_id = p_user_id;

  -- Preserve shared match history without retaining a reference to the deleted creator.
  update public.games
  set creator_id = null
  where creator_id = p_user_id;

  -- Existing foreign keys cascade memberships, votes, sport stats, and reviews.
  delete from public.profiles
  where id = p_user_id;

  -- Reviews contribute to cached park aggregates, so remove their effect as well.
  if coalesce(array_length(v_reviewed_park_ids, 1), 0) > 0 then
    update public.parks_ratings ratings
    set quality_avg = coalesce((
          select avg(review.quality)::numeric(3, 2)
          from public.park_reviews review
          where review.park_id = ratings.park_id
        ), 0),
        facilities_avg = coalesce((
          select avg(review.facilities)::numeric(3, 2)
          from public.park_reviews review
          where review.park_id = ratings.park_id
        ), 0),
        activity_avg = coalesce((
          select avg(review.activity)::numeric(3, 2)
          from public.park_reviews review
          where review.park_id = ratings.park_id
        ), 0),
        overall_avg = coalesce((
          select (
            avg(review.quality)
            + avg(review.facilities)
            + avg(review.activity)
          ) / 3.0
          from public.park_reviews review
          where review.park_id = ratings.park_id
        ), 0),
        quality_count = (
          select count(*)
          from public.park_reviews review
          where review.park_id = ratings.park_id
        ),
        facilities_count = (
          select count(*)
          from public.park_reviews review
          where review.park_id = ratings.park_id
        ),
        activity_count = (
          select count(*)
          from public.park_reviews review
          where review.park_id = ratings.park_id
        ),
        updated_at = now()
    where ratings.park_id = any(v_reviewed_park_ids);
  end if;
end;
$$;

revoke execute on function public.delete_user_data(uuid)
from public, anon, authenticated;

grant execute on function public.delete_user_data(uuid)
to service_role;
