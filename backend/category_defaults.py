# 預設分類定義
DEFAULT_CATEGORIES = {
    "expense": [
        {"name": "食", "sub": ["早餐", "午餐", "晚餐", "宵夜"]},
        {"name": "衣", "sub": []},
        {"name": "住", "sub": []},
        {"name": "行", "sub": []},
        {"name": "育", "sub": []},
        {"name": "樂", "sub": []},
        {"name": "金融", "sub": []},
        {"name": "其他", "sub": []},
        {"name": "未分類", "sub": []}, # 系統預設
    ],
    "income": [
        {"name": "工作", "sub": ["正職", "兼職"]},
        {"name": "投資", "sub": []},
        {"name": "其他", "sub": []},
        {"name": "未分類", "sub": []}, # 系統預設
    ]
}

def seed_categories(db, user_id):
    """
    為新使用者初始化預設分類
    """
    from .models import Category
    
    for category_type, categories in DEFAULT_CATEGORIES.items():
        for cat_data in categories:
            # 建立主類別
            parent = Category(
                user_id=user_id,
                name=cat_data["name"],
                type=category_type,
                parent_id=None
            )
            db.add(parent)
            db.flush() # 獲取 parent.id
            
            # 建立子類別
            for sub_name in cat_data["sub"]:
                child = Category(
                    user_id=user_id,
                    name=sub_name,
                    type=category_type,
                    parent_id=parent.id
                )
                db.add(child)
    db.commit()
