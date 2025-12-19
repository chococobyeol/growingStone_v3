-- ⚠️ 주의: 이 코드를 실행하면 프로젝트의 모든 데이터가 삭제됩니다!

-- 1. 트리거 및 함수 삭제
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- 2. 테이블 삭제 (참조 관계의 역순으로 삭제해야 함)
-- Stones는 Recipes와 Profiles를 참조하므로 가장 먼저 삭제
drop table if exists public.stones;

-- User_materials는 Profiles를 참조하므로 삭제
drop table if exists public.user_materials;

-- Mineral_recipes는 독립적이지만 Stones가 참조했었으므로 Stones 삭제 후 삭제
drop table if exists public.mineral_recipes;

-- 최상위 부모 테이블인 Profiles 삭제
drop table if exists public.profiles;

-- (참고: RLS 정책은 테이블이 삭제되면 자동으로 함께 사라집니다.)