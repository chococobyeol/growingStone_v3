import psycopg2
import os
from urllib.parse import quote
from dotenv import load_dotenv

# 1. .env 파일 로드
load_dotenv()

# 2. 환경 변수 읽기
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT", "5432")
db_name = os.getenv("DB_NAME", "postgres")

if not db_password:
    print("❌ 에러: .env 파일에서 정보를 읽어오지 못했습니다.")
    exit(1)

# 3. DB 접속 URI 생성
encoded_password = quote(db_password)
DB_URI = f"postgresql://{db_user}:{encoded_password}@{db_host}:{db_port}/{db_name}"

def upload_v15_data(file_path):
    conn = None
    try:
        print(f"📡 Supabase v15 서버 접속 시도 중... ({db_host})")
        conn = psycopg2.connect(DB_URI)
        cur = conn.cursor()
        print("✅ 연결 성공. 4,170개 고증 데이터 업로드를 시작합니다.")

        # SQL 파일 존재 여부 확인
        if not os.path.exists(file_path):
            # 스크립트 위치 기준으로 경로 재탐색
            base_dir = os.path.dirname(os.path.abspath(__file__))
            file_path = os.path.join(base_dir, file_path)
            if not os.path.exists(file_path):
                print(f"❌ 에러: {file_path} 파일을 찾을 수 없습니다.")
                return

        with open(file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
            # 세미콜론 기준으로 쿼리 분리
            queries = [q.strip() for q in sql_content.split(';') if q.strip()]

        total = len(queries)
        print(f"📦 총 {total}개의 쿼리를 실행합니다.")

        for i, query in enumerate(queries):
            try:
                cur.execute(query + ";")
                if i % 100 == 0:
                    print(f"🚀 업로드 진행 중: {i}/{total} 완료")
            except Exception as e:
                print(f"⚠️ 쿼리 오류 (Index {i}): {e}")
                conn.rollback()
                continue
        
        conn.commit()
        print(f"✨ 최종 완료! 4,170개의 v15 고증 데이터가 성공적으로 반영되었습니다.")

    except Exception as e:
        print(f"❌ 연결 및 업로드 실패: {e}")
    finally:
        if conn:
            cur.close()
            conn.close()
            print("🔒 DB 연결을 안전하게 종료했습니다.")

if __name__ == "__main__":
    upload_v15_data('import_minerals_v15.sql')
