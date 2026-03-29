from sqlalchemy import Column, Integer, String, Enum, DateTime, ForeignKey
from sqlalchemy.orm import relationship
import enum
from database import Base

class TaskStatus(str, enum.Enum):
    TODO = "To-Do"
    IN_PROGRESS = "In Progress"
    DONE = "Done"

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    description = Column(String, nullable=False)
    due_date = Column(DateTime, nullable=False)
    status = Column(Enum(TaskStatus), default=TaskStatus.TODO, nullable=False)
    
    blocked_by_id = Column(Integer, ForeignKey("tasks.id"), nullable=True)
    recurrence_interval = Column(String, nullable=True) # "Daily" or "Weekly"
    
    # We can add a relationship to itself if needed
    blocked_by = relationship("Task", remote_side=[id])
