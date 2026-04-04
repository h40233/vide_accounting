from celery_app import celery_app
from database import SessionLocal
from models import User, Account, Category, Transaction, Schedule, Notification
from datetime import datetime, timedelta, time
import pytz

# 設定時區
tz = pytz.timezone("Asia/Taipei")

@celery_app.task(name="tasks.process_schedules")
def process_schedules():
    """
    掃描所有到期的自動記帳排程並執行扣款。
    """
    db = SessionLocal()
    now = datetime.now(tz)
    
    # 找出所有已啟用且到期的排程
    schedules = db.query(Schedule).filter(
        Schedule.enabled == True,
        Schedule.next_run <= now
    ).all()
    
    for sch in schedules:
        # 1. 建立交易紀錄 (Transaction)
        final_amount = sch.amount if sch.type == "income" else -sch.amount
        
        new_tx = Transaction(
            user_id=sch.user_id,
            account_id=sch.account_id,
            category_id=sch.category_id,
            amount=final_amount,
            type=sch.type,
            note=f"[自動記帳] {sch.note}" if sch.note else "[自動記帳]"
        )
        db.add(new_tx)
        
        # 2. 發送成功通知 (Notification)
        status_msg = f"已成功自動記錄一筆 {sch.type}：{abs(sch.amount)} 元"
        notification = Notification(
            user_id=sch.user_id,
            content=status_msg,
            type="auto_log"
        )
        db.add(notification)
        
        # 3. 檢查餘額不足 (Negative Balance Warning)
        account = db.query(Account).filter(Account.id == sch.account_id).first()
        if account and (account.balance + final_amount) < 0:
            warn_msg = f"注意：帳戶 [{account.name}] 在自動扣款後餘額已變為負數 ({account.balance + final_amount} 元)。"
            db.add(Notification(
                user_id=sch.user_id,
                content=warn_msg,
                type="failed"
            ))
        
        # 4. 更新下次執行時間
        sch.next_run = sch.next_run + timedelta(days=sch.interval_days)
        
    db.commit()
    db.close()
    return f"Processed {len(schedules)} schedules."

@celery_app.task(name="tasks.send_daily_reminders")
def send_daily_reminders():
    """
    每日晚上 9:00 檢查用戶今日是否已記帳。
    """
    db = SessionLocal()
    today_start = datetime.combine(datetime.now(tz).date(), time.min).replace(tzinfo=tz)
    
    # 遍歷所有使用者
    users = db.query(User).all()
    reminded_count = 0
    
    for user in users:
        # 檢查今天是否有交易紀錄
        has_tx = db.query(Transaction).filter(
            Transaction.user_id == user.id,
            Transaction.transaction_date >= today_start
        ).first()
        
        if not has_tx:
            # 發送提醒通知
            reminder = Notification(
                user_id=user.id,
                content="晚上好！今天好像還沒記帳喔，趁現在花一點點時間記錄一下吧！",
                type="reminder"
            )
            db.add(reminder)
            reminded_count += 1
            
    db.commit()
    db.close()
    return f"Sent missing entry reminders to {reminded_count} users."
