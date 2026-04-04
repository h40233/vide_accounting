from celery import Celery
import os
from celery.schedules import crontab

# Redis / Celery 配置
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")

celery_app = Celery(
    "accounting_tasks",
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=["tasks"] # 這裡我們會實作具體的任務邏輯
)

# 定義定時排程 (Beat Settings)
celery_app.conf.beat_schedule = {
    "process-recurring-schedules-daily-at-midnight": {
        "task": "tasks.process_schedules",
        "schedule": crontab(hour=0, minute=0), # 每日午夜 00:00 執行
    },
    "daily-missing-reminder-at-9pm": {
        "task": "tasks.send_daily_reminders",
        "schedule": crontab(hour=21, minute=0), # 每天晚上 9:00 執行
    }
}

celery_app.conf.timezone = "Asia/Taipei"
