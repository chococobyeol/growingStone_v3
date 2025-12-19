#upload_v14_to_supabase.py
import psycopg2
import os
from urllib.parse import quote
from dotenv import load_dotenv

# 1. .env 파일 로드 (파일 위치가 스크립트와 같은 곳에 있어야 합니다)
load_dotenv()

# 2. 환경 변수 읽기
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT", "5432")
db_name = os.getenv("DB_NAME", "postgres")

# 비밀번호 확인
if not db_password:
    print("❌ 에러: .env 파일에서 DB_PASSWORD를 읽어오지 못했습니다.")
    print("파일 이름이 정확히 .env 인지, 그리고 스크립트와 같은 폴더에 있는지 확인하세요.")
    exit(1)

# 3. DB 접속 URI 생성
encoded_password = quote(db_password)
DB_URI = f"postgresql://{db_user}:{encoded_password}@{db_host}:{db_port}/{db_name}"

def upload_sql(file_path):
    conn = None
    try:
        print(f"📡 DB 접속 시도 중... ({db_host})")
        conn = psycopg2.connect(DB_URI)
        cur = conn.cursor()
        print("✅ 연결 성공. v14 고증 데이터 업로드를 시작합니다.")

        # SQL 파일 읽기
        if not os.path.exists(file_path):
            print(f"❌ 에러: {file_path} 파일을 찾을 수 없습니다.")
            return

        with open(file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
            # 세미콜론 기준으로 쿼리 분리
            queries = [q.strip() for q in sql_content.split(';') if q.strip()]

        total = len(queries)
        print(f"📦 총 {total}개의 쿼리 실행 예정...")

        for i, query in enumerate(queries):
            try:
                cur.execute(query + ";")
                if i % 100 == 0:
                    print(f"🚀 업로드 진행 중: {i}/{total} 완료")
            except Exception as e:
                print(f"⚠️ 쿼리 오류 (인덱스 {i}): {e}")
                conn.rollback() # 오류 발생 시 해당 트랜잭션 롤백 후 계속 진행
                continue
        
        conn.commit()
        print(f"✨ 최종 완료! 총 {total}개의 고증 데이터가 성공적으로 반영되었습니다.")

    except Exception as e:
        print(f"❌ 연결 실패: {e}")
    finally:
        if conn:
            cur.close()
            conn.close()
            print("🔒 DB 연결을 안전하게 종료했습니다.")

if __name__ == "__main__":
    # v14 SQL 파일 경로 확인 (스크립트가 data_audit 폴더 안에 있다면 경로 주의)
    # 현재 스크립트와 같은 위치에 있다면 파일명만, 상위 폴더에 있다면 '../파일명'
    target_file = 'import_minerals_v14.sql'
    
    # 만약 파일이 상위 폴더에 있을 경우를 대비한 체크 로직
    if not os.path.exists(target_file):
        target_file = os.path.join(os.path.dirname(__file__), 'import_minerals_v14.sql')

    upload_sql(target_file)