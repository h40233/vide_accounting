from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, DECIMAL, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
import uuid

# 自動生成 UUID 的輔助函式
def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=generate_uuid)
    google_sub = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    display_name = Column(String)
    avatar_url = Column(Text)
    is_onboarded = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    accounts = relationship("Account", back_populates="user")
    transactions = relationship("Transaction", back_populates="user")
    memberships = relationship("GroupMembership", back_populates="user")
    categories = relationship("Category", back_populates="user")

class Category(Base):
    __tablename__ = "categories"
    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=True) # NULL 表示系統預設
    name = Column(String, nullable=False)
    type = Column(String, nullable=False) # 'income', 'expense'
    parent_id = Column(String, ForeignKey("categories.id", ondelete="CASCADE"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="categories")
    subcategories = relationship("Category", backref=relationship("Category", remote_side=[id]))

class Account(Base):
    __tablename__ = "accounts"
    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String, nullable=False)
    balance = Column(DECIMAL(15, 2), nullable=False, default=0.00)
    type = Column(String, nullable=False) # 'liquid', 'savings', 'credit'
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="accounts")
    transactions = relationship("Transaction", back_populates="account")

class Group(Base):
    __tablename__ = "groups"
    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String, nullable=False)
    creator_id = Column(String, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    members = relationship("GroupMembership", back_populates="group")

class GroupMembership(Base):
    __tablename__ = "group_memberships"
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    group_id = Column(String, ForeignKey("groups.id", ondelete="CASCADE"), primary_key=True)
    role = Column(String, nullable=False, default="member")
    show_balance = Column(Boolean, nullable=False, default=False)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="memberships")
    group = relationship("Group", back_populates="members")

class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    account_id = Column(String, ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False)
    category_id = Column(String, ForeignKey("categories.id"), nullable=False)
    amount = Column(DECIMAL(15, 2), nullable=False)
    note = Column(Text)
    transaction_date = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="transactions")
    account = relationship("Account", back_populates="transactions")
    category = relationship("Category")

class Schedule(Base):
    __tablename__ = "schedules"
    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    account_id = Column(String, ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False)
    category_id = Column(String, ForeignKey("categories.id"), nullable=False)
    amount = Column(DECIMAL(15, 2), nullable=False)
    note = Column(Text)
    interval_days = Column(Integer, nullable=False)
    next_run = Column(DateTime(timezone=True), nullable=False)
    enabled = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Notification(Base):
    __tablename__ = "notifications"
    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    content = Column(Text, nullable=False)
    type = Column(String, nullable=False) # 'reminder', 'auto_log', 'failed'
    is_read = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
