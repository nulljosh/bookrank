-- Share links + per-row cover. A share token exposes title, content, cover and the cached
-- narration scripts of one row to anyone holding the token. Never the resume position,
-- never the owner, never a listing.
alter table bookrank_summaries add column if not exists share_token text unique;
alter table bookrank_summaries add column if not exists cover text;

create or replace function shared_summary(t text)
returns table (title text, content text, cover text, scripts jsonb)
language sql security definer stable set search_path = public as $$
  select title, content, cover,
         case when listen->>'for' = (to_jsonb(updated_at) #>> '{}') then coalesce(listen->'chapters', '{}'::jsonb) else '{}'::jsonb end
  from bookrank_summaries where share_token = t and t is not null;
$$;

-- Called by /api/narrate for shared listeners so the second person to open a link does
-- not pay for the model again. Resets pos only when the cache was already stale.
create or replace function cache_shared_script(t text, ch text, script jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  update bookrank_summaries set listen =
    case when listen->>'for' = (to_jsonb(updated_at) #>> '{}')
         then jsonb_set(listen, array['chapters', ch], script, true)
         else jsonb_build_object('for', to_jsonb(updated_at), 'chapters', jsonb_build_object(ch, script), 'pos', jsonb_build_object('ch', 0, 'line', 0)) end
  where share_token = t and t is not null;
end $$;

revoke all on function shared_summary(text) from public;
revoke all on function cache_shared_script(text, text, jsonb) from public;
grant execute on function shared_summary(text) to anon, authenticated;
grant execute on function cache_shared_script(text, text, jsonb) to anon, authenticated;
