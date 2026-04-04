from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .database import get_db
from .models import User, Account, Category, Transaction, Group, GroupMembership, Schedule, Notification
from .auth import verify_google_token, create_access_token, get_current_user
from pydantic import BaseModel
from decimal import Decimal
from typing import Optional, List
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI(title="Accounting App API")

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # 開發環境允許所有來源
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from .category_defaults import seed_categories

# Google Login Endpoint
@app.post("/auth/google")
async def google_login(token: str, db: Session = Depends(get_db)):
    """
    接收前端傳來的 Google ID Token，驗證後回傳 JWT。
    若是新用戶，則自動建立 User、預設帳戶與「預設分類」。
    """
    user_data = verify_google_token(token)
    google_sub = user_data.get("sub")
    email = user_data.get("email")
    name = user_data.get("name")
    picture = user_data.get("picture")

    db_user = db.query(User).filter(User.google_sub == google_sub).first()
    
    if not db_user:
        # 1. 建立新用戶
        db_user = User(
            google_sub=google_sub,
            email=email,
            display_name=name,
            avatar_url=picture
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        # 2. 建立預設「現金」帳戶
        default_account = Account(
            user_id=db_user.id,
            name="現金",
            type="liquid",
            balance=0.00
        )
        db.add(default_account)
        
        # 3. 初始化預設分類 (食、衣、住、行...等)
        seed_categories(db, db_user.id)
        db.commit()

    access_token = create_access_token(data={"sub": db_user.id})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    """
    獲取當前登入用戶資訊，包含導覽狀態。
    """
    return {
        "id": current_user.id,
        "email": current_user.email,
        "display_name": current_user.display_name,
        "avatar_url": current_user.avatar_url,
        "is_onboarded": current_user.is_onboarded
    }

@app.post("/me/onboarded")
async def set_onboarded(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    標記用戶已完成導覽。
    """
    current_user.is_onboarded = True
    db.commit()
    return {"status": "success"}

# --- Accounts API ---
@app.get("/accounts")
async def list_accounts(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    列出使用者所有帳戶與餘額。
    """
    accounts = db.query(Account).filter(Account.user_id == current_user.id).all()
    return accounts

@app.post("/accounts")
async def create_account(name: str, type: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    建立新帳戶。
    """
    new_account = Account(
        user_id=current_user.id,
        name=name,
        type=type,
        balance=0.00
    )
    db.add(new_account)
    db.commit()
    db.refresh(new_account)
    return new_account

@app.delete("/accounts/{account_id}")
async def delete_account(account_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    [安全保護]：禁止刪除有記帳紀錄的帳戶。
    """
    account = db.query(Account).filter(Account.id == account_id, Account.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    
    # 檢查有無交易紀錄
    tx_count = db.query(Transaction).filter(Transaction.account_id == account_id).count()
    if tx_count > 0:
        raise HTTPException(
            status_code=400, 
            detail="禁止刪除含有交易紀錄的帳戶。請先刪除流水或移動資料。"
        )
    
    db.delete(account)
    db.commit()
    return {"status": "success"}

# --- Categories API ---
class CategoryCreate(BaseModel):
    name: str
    type: str # 'income', 'expense'
    parent_id: Optional[str] = None

@app.post("/categories")
async def create_category(item: CategoryCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    新增分類，強制執行「兩層結構」限制。
    """
    if item.parent_id:
        parent = db.query(Category).filter(Category.id == item.parent_id, Category.user_id == current_user.id).first()
        if not parent:
            raise HTTPException(status_code=404, detail="Parent category not found")
        if parent.parent_id is not None:
            raise HTTPException(status_code=400, detail="分類層級限制：子類別無法再擁有子類別。")

    new_cat = Category(
        user_id=current_user.id,
        name=item.name,
        type=item.type,
        parent_id=item.parent_id
    )
    db.add(new_cat)
    db.commit()
    db.refresh(new_cat)
    return new_cat

@app.get("/categories")
async def list_categories(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    獲取使用者的分類列表 (樹狀結構)。
    """
    categories = db.query(Category).filter(Category.user_id == current_user.id, Category.parent_id == None).all()
    result = []
    for cat in categories:
        result.append({
            "id": cat.id,
            "name": cat.name,
            "type": cat.type,
            "sub": [{"id": s.id, "name": s.name} for s in db.query(Category).filter(Category.parent_id == cat.id).all()]
        })
    return result

@app.delete("/categories/{category_id}")
async def delete_category(category_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    [安全保護]：刪除類別時，將所有相關交易移動到「未分類」。
    """
    target_cat = db.query(Category).filter(Category.id == category_id, Category.user_id == current_user.id).first()
    if not target_cat:
        raise HTTPException(status_code=404, detail="Category not found")
    
    if target_cat.name == "未分類":
        raise HTTPException(status_code=400, detail="禁止刪除系統保留之「未分類」項目。")

    uncategorized = db.query(Category).filter(
        Category.user_id == current_user.id, 
        Category.name == "未分類", 
        Category.type == target_cat.type,
        Category.parent_id == None
    ).first()
    
    if not uncategorized:
        uncategorized = Category(user_id=current_user.id, name="未分類", type=target_cat.type, parent_id=None)
        db.add(uncategorized)
        db.flush()

    if target_cat.parent_id is None:
        sub_ids = [s.id for s in db.query(Category).filter(Category.parent_id == target_cat.id).all()]
        db.query(Transaction).filter(Transaction.category_id.in_([target_cat.id] + sub_ids)).update({Transaction.category_id: uncategorized.id}, synchronize_session=False)
    else:
        db.query(Transaction).filter(Transaction.category_id == target_cat.id).update({Transaction.category_id: uncategorized.id}, synchronize_session=False)

    db.delete(target_cat)
    db.commit()
    return {"status": "success", "message": "分類已刪除，原交易已遷移至「未分類」。"}

# --- Groups API ---
from .models import Group, GroupMembership

class GroupCreate(BaseModel):
    name: str

@app.post("/groups")
async def create_group(item: GroupCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    建立新群組，並將建立者設為 Owner。
    """
    new_group = Group(
        name=item.name,
        creator_id=current_user.id
    )
    db.add(new_group)
    db.flush() # 獲取 group.id

    # 建立成員關係
    membership = GroupMembership(
        user_id=current_user.id,
        group_id=new_group.id,
        role="owner",
        show_balance=False # 預設不顯示餘額
    )
    db.add(membership)
    db.commit()
    db.refresh(new_group)
    return new_group

@app.post("/groups/{group_id}/invite")
async def invite_to_group(group_id: str, email: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    邀請成員加入群組 (目前簡化為直接加入)。
    """
    # 權限檢查：只有 Owner 能邀請 (暫時)
    owner_check = db.query(GroupMembership).filter(
        GroupMembership.group_id == group_id, 
        GroupMembership.user_id == current_user.id, 
        GroupMembership.role == "owner"
    ).first()
    
    if not owner_check:
        raise HTTPException(status_code=403, detail="Only group owners can invite members")

    # 尋找使用者
    invited_user = db.query(User).filter(User.email == email).first()
    if not invited_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # 檢查是否已在群組
    exists = db.query(GroupMembership).filter(
        GroupMembership.group_id == group_id, 
        GroupMembership.user_id == invited_user.id
    ).first()
    if exists:
        raise HTTPException(status_code=400, detail="User is already in the group")

    # 加入成員
    new_member = GroupMembership(
        user_id=invited_user.id,
        group_id=group_id,
        role="member",
        show_balance=False
    )
    db.add(new_member)
    db.commit()
    return {"status": "success", "message": f"{email} added to the group"}

@app.patch("/groups/{group_id}/privacy")
async def update_group_privacy(group_id: str, show_balance: bool, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    更新個人在群組內的可見性設定。
    """
    membership = db.query(GroupMembership).filter(
        GroupMembership.group_id == group_id, 
        GroupMembership.user_id == current_user.id
    ).first()
    
    if not membership:
        raise HTTPException(status_code=404, detail="Not a member of this group")
    
    membership.show_balance = show_balance
    db.commit()
    return {"status": "success", "show_balance": show_balance}

@app.get("/groups/{group_id}/transactions")
async def list_group_transactions(group_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    獲取群組成員共享的交易流水。
    """
    # 權限檢查：必須是該群組成員
    member_check = db.query(GroupMembership).filter(
        GroupMembership.group_id == group_id, 
        GroupMembership.user_id == current_user.id
    ).first()
    if not member_check:
        raise HTTPException(status_code=403, detail="Not a member of this group")

    # 找出群組所有成員 ID
    member_ids = [m.user_id for m in db.query(GroupMembership).filter(GroupMembership.group_id == group_id).all()]
    
    # 拉取所有成員的交易紀錄
    transactions = db.query(Transaction).filter(Transaction.user_id.in_(member_ids)).order_by(Transaction.transaction_date.desc()).all()
    
    return transactions

@app.get("/groups")
async def list_my_groups(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    列出當前使用者所屬的所有群組。
    """
    # 先抓出所有的 membership，再關聯找出群組名稱
    memberships = db.query(GroupMembership).filter(GroupMembership.user_id == current_user.id).all()
    group_ids = [m.group_id for m in memberships]
    
    groups = db.query(Group).filter(Group.id.in_(group_ids)).all()
    
    # 組合回傳資料 (包含角色與自訂設定)
    result = []
    for g in groups:
        m = next(ms for ms in memberships if ms.group_id == g.id)
        result.append({
            "id": g.id,
            "name": g.name,
            "role": m.role,
            "show_balance": m.show_balance
        })
    return result

# --- Transactions API ---
class TransactionCreate(BaseModel):
    account_id: str
    category_id: str 
    amount: Decimal
    type: str # 'income', 'expense'
    note: Optional[str] = ""

@app.post("/transactions")
async def create_transaction(
    item: TransactionCreate, 
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """
    新增交易。category_id 為必填。
    """
    account = db.query(Account).filter(Account.id == item.account_id, Account.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    
    # 驗證分類
    category = db.query(Category).filter(Category.id == item.category_id).first()
    if not category:
        raise HTTPException(status_code=400, detail="Invalid category_id")

    final_amount = item.amount if item.type == "income" else -item.amount

    new_tx = Transaction(
        user_id=current_user.id,
        account_id=item.account_id,
        category_id=item.category_id,
        amount=final_amount,
        type=item.type,
        note=item.note
    )
    db.add(new_tx)
    db.commit()
    db.refresh(new_tx)
    return new_tx

@app.get("/transactions")
async def list_transactions(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    列出所有交易流水。
    """
    txs = db.query(Transaction).filter(Transaction.user_id == current_user.id).order_by(Transaction.transaction_date.desc()).all()
    return txs

# --- Schedules API (Recurring) ---
class ScheduleCreate(BaseModel):
    account_id: str
    category_id: str
    amount: Decimal
    type: str
    note: Optional[str] = ""
    interval_days: int
    next_run: datetime

@app.post("/schedules")
async def create_schedule(item: ScheduleCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    建立自動記帳排程。
    """
    new_sch = Schedule(
        user_id=current_user.id,
        account_id=item.account_id,
        category_id=item.category_id,
        amount=item.amount,
        type=item.type,
        note=item.note,
        interval_days=item.interval_days,
        next_run=item.next_run
    )
    db.add(new_sch)
    db.commit()
    db.refresh(new_sch)
    return new_sch

@app.get("/schedules")
async def list_schedules(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    列出所有自動記帳規則。
    """
    schedules = db.query(Schedule).filter(Schedule.user_id == current_user.id).all()
    return schedules

@app.delete("/schedules/{id}")
async def delete_schedule(id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    取消自動記帳排程。
    """
    sch = db.query(Schedule).filter(Schedule.id == id, Schedule.user_id == current_user.id).first()
    if not sch:
        raise HTTPException(status_code=404, detail="Schedule not found")
    db.delete(sch)
    db.commit()
    return {"status": "success"}

# --- Notifications API ---
@app.get("/notifications")
async def list_notifications(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    獲取系統內通知。
    """
    notifs = db.query(Notification).filter(Notification.user_id == current_user.id).order_by(Notification.created_at.desc()).all()
    return notifs

@app.patch("/notifications/{id}/read")
async def mark_notification_read(id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    標記通知為已讀。
    """
    notif = db.query(Notification).filter(Notification.id == id, Notification.user_id == current_user.id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    notif.is_read = True
    db.commit()
    return {"status": "success"}

@app.get("/")
async def root():
    return {"message": "Accounting API is running!"}
