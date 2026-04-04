from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://admin:password@db/accounting_db")

# 建立 SQLAlchemy Engine
engine = create_engine(DATABASE_URL)

# 建立 SessionLocal 類別
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 建立 Base 類別供 Model 繼承
Base = declarative_base()

# Dependency: 獲取資料庫 Session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
