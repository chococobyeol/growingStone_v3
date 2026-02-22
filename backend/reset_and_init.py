#!/usr/bin/env python3
"""롤백 후 스키마 재적용 + v16 광물 데이터 업로드. .env 필요."""
import os
import sys
import re
from pathlib import Path
from urllib.parse import quote

try:
    import psycopg2
except ImportError:
    print("❌ psycopg2 필요: pip install psycopg2-binary")
    sys.exit(1)

from dotenv import load_dotenv
load_dotenv()

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "postgres")

if not DB_PASSWORD:
    print("❌ .env에서 DB 정보를 읽지 못했습니다.")
    sys.exit(1)

DB_URI = f"postgresql://{DB_USER}:{quote(DB_PASSWORD)}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent

def run_sql_file(conn, path: Path, desc: str) -> bool:
    """SQL 파일 전체 실행 (psycopg2)."""
    if not path.exists():
        print(f"❌ 파일 없음: {path}")
        return False
    sql = path.read_text(encoding="utf-8")
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        return True
    except Exception as e:
        print(f"⚠️ {desc} 실패: {e}")
        conn.rollback()
        return False

def run_import_file(cur) -> bool:
    """INSERT 위주 import_minerals_v16.sql은 psycopg2로 실행."""
    import_path = PROJECT_ROOT / "data_audit" / "import_minerals_v16.sql"
    if not import_path.exists():
        print(f"❌ 파일 없음: {import_path}")
        return False
    sql = import_path.read_text(encoding="utf-8")
    queries = [q.strip() for q in sql.split(";") if q.strip()]
    for i, q in enumerate(queries):
        try:
            q = q.replace('"system": ""', '"system": "unknown"')
            q = re.sub(r",\s*''\s*\)\s*$", ", 'unknown')", q)
            cur.execute(q + ";")
            if i % 500 == 0 and i > 0:
                print(f"   ... {i}/{len(queries)} 완료")
        except Exception as e:
            print(f"⚠️ import 쿼리 {i+1} 오류: {e}")
            return False
    return True

def main():
    conn = None
    try:
        print(f"📡 DB 연결 중... ({DB_HOST})")
        conn = psycopg2.connect(DB_URI)

        # 1. 롤백
        print("🔄 1/3 롤백 실행...")
        if not run_sql_file(conn, SCRIPT_DIR / "rollback.sql", "rollback"):
            sys.exit(1)
        print("   ✅ 롤백 완료")

        # 2. 스키마
        print("🔄 2/3 스키마 적용...")
        if not run_sql_file(conn, SCRIPT_DIR / "schema.sql", "schema"):
            sys.exit(1)
        print("   ✅ 스키마 완료")

        # 3. 광물 데이터
        print("🔄 3/3 v16 광물 데이터 업로드...")
        cur = conn.cursor()
        if not run_import_file(cur):
            conn.rollback()
            sys.exit(1)
        conn.commit()
        cur.close()
        print("   ✅ 광물 데이터 업로드 완료")

        print("\n✨ 초기화 완료!")
    except Exception as e:
        print(f"❌ 오류: {e}")
        sys.exit(1)
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
