-- 우리 가족 대시보드: 부모가 '🧚 요정 추가'로 새 요정 그림을 올릴 수 있게 허용
-- Supabase → SQL Editor 에 통째로 붙여 넣고 Run 을 한 번 누르면 됩니다. (supabase-assets.sql 을 실행한 뒤)

create or replace function public.save_dashboard_asset(pin_input text, asset_name text, asset_data text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.get_dashboard_state(pin_input);
  if asset_name not in ('romi.jpg', 'fairy-1-pink.jpg', 'fairy-2-mint.jpg', 'fairy-3-yellow.jpg',
                        'fairy-4-lavender.jpg', 'fairy-heartbox.png')
     and asset_name !~ '^fairy-c[0-9]{1,2}\.jpg$' then
    raise exception 'BAD_ASSET_NAME';
  end if;
  if asset_data not like 'data:image/%' or length(asset_data) > 300000 then
    raise exception 'BAD_ASSET_DATA';
  end if;
  insert into public.dashboard_assets(name, data, updated_at)
  values (asset_name, asset_data, now())
  on conflict (name) do update set data = excluded.data, updated_at = now();
end;
$$;
