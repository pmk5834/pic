-- 우리 가족 대시보드: 캐릭터 그림 비공개 보관함
-- Supabase → SQL Editor 에 통째로 붙여 넣고 Run 을 한 번 누르면 됩니다.
-- 가족 비밀번호 확인은 기존 get_dashboard_state 함수를 그대로 사용합니다
-- (비밀번호가 틀리면 그 함수가 INVALID_PIN 오류를 내고, 아래 함수도 같이 멈춥니다).

create table if not exists public.dashboard_assets (
  name       text primary key,
  data       text not null,
  updated_at timestamptz not null default now()
);

-- 테이블은 바깥에서 직접 못 읽게 잠근다 (아래 함수로만 접근)
alter table public.dashboard_assets enable row level security;
revoke all on public.dashboard_assets from anon, authenticated;

-- 비밀번호가 맞으면 그림 전체를 돌려준다
create or replace function public.get_dashboard_assets(pin_input text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.get_dashboard_state(pin_input);
  return coalesce((select jsonb_object_agg(name, data) from public.dashboard_assets), '{}'::jsonb);
end;
$$;

-- 비밀번호가 맞으면 그림 한 장을 저장한다 (정해진 파일 이름, 이미지, 300KB 이하만)
create or replace function public.save_dashboard_asset(pin_input text, asset_name text, asset_data text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.get_dashboard_state(pin_input);
  if asset_name not in ('romi.jpg', 'fairy-1-pink.jpg', 'fairy-2-mint.jpg', 'fairy-3-yellow.jpg',
                        'fairy-4-lavender.jpg', 'fairy-heartbox.png') then
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

revoke all on function public.get_dashboard_assets(text) from public;
revoke all on function public.save_dashboard_asset(text, text, text) from public;
grant execute on function public.get_dashboard_assets(text) to anon, authenticated;
grant execute on function public.save_dashboard_asset(text, text, text) to anon, authenticated;
