# v16 광물 데이터 업로드 (pm_ids, gacha_weight)

## 컬럼

| 컬럼 | 타입 | 설명 |
|------|------|------|
| pm_ids | int[] | 출현 Paragenetic Mode 번호 목록 (추적/검증용) |
| gacha_weight | float | 원소 뽑기 확률 가중치 (PM 종 수 합) |

## 순서

1. **스키마 마이그레이션** (최초 1회)
   ```sql
   alter table public.mineral_recipes add column if not exists pm_ids int[] default '{}';
   alter table public.mineral_recipes add column if not exists gacha_weight double precision default 1.0;
   ```

2. **변환**
   ```bash
   python convert_final_v15_perfect.py
   ```
   → `import_minerals_v16.sql`, `minerals_audit_v16.csv` 생성

3. **업로드**
   ```bash
   python upload_v16_to_supabase.py
   ```
