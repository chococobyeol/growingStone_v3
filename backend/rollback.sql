-- ⚠️ 주의: 이 코드를 실행하면 프로젝트의 모든 데이터가 삭제됩니다!

-- 1) 뷰 삭제
drop view if exists public.weekly_shared_stone_ranking;

-- 2) 트리거 및 함수 삭제
drop trigger if exists on_auth_user_created on auth.users;

-- updated_at 트리거 정리
drop trigger if exists trg_profiles_updated_at on public.profiles;
drop trigger if exists trg_mineral_recipes_updated_at on public.mineral_recipes;
drop trigger if exists trg_user_materials_updated_at on public.user_materials;
drop trigger if exists trg_stones_updated_at on public.stones;
drop trigger if exists trg_shared_stones_updated_at on public.shared_stones;

-- 3) 테이블 삭제 (참조 관계 역순)
drop table if exists public.stone_likes;
drop table if exists public.shared_stones;
drop table if exists public.stones;
drop table if exists public.user_materials;
drop table if exists public.mineral_recipes;
drop table if exists public.profiles;

-- 4) 테이블 삭제 후 함수 삭제
drop function if exists public.purchase_element_pack();
drop function if exists public.handle_new_user();
drop function if exists public.random_default_nickname();
drop function if exists public.set_updated_at();
drop function if exists public.kst_week_start(timestamp with time zone);