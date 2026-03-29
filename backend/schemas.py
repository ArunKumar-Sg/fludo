from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from models import TaskStatus

class TaskBase(BaseModel):
    title: str
    description: str
    due_date: datetime
    status: TaskStatus
    blocked_by_id: Optional[int] = None
    recurrence_interval: Optional[str] = None

class TaskCreate(TaskBase):
    pass

class TaskUpdate(TaskBase):
    pass

class Task(TaskBase):
    id: int

    class Config:
        from_attributes = True
