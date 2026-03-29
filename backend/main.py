import asyncio
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
import time
import os
from dotenv import load_dotenv

load_dotenv()

import json
from google import genai
from pydantic import BaseModel
from datetime import timedelta

import models, schemas, database
from database import SessionLocal
from datetime import datetime

models.Base.metadata.create_all(bind=database.engine)

def init_dummy_data():
    db = SessionLocal()
    try:
        if db.query(models.Task).count() == 0:
            t1 = models.Task(title="Master Flutter UI", description="Implement glassmorphism and animations.", due_date=datetime.now() + timedelta(days=1), status=models.TaskStatus.IN_PROGRESS)
            t2 = models.Task(title="Backend AI Integration", description="Connect Gemini API to generate intelligent tasks.", due_date=datetime.now() + timedelta(days=2), status=models.TaskStatus.TODO)
            db.add(t1)
            db.add(t2)
            db.commit()
            db.refresh(t2)
            
            t3 = models.Task(title="Submit Flodo Assignment", description="Record demographic video and push to GitHub.", due_date=datetime.now() + timedelta(days=3), status=models.TaskStatus.TODO, blocked_by_id=t2.id)
            db.add(t3)
            db.commit()
    finally:
        db.close()

init_dummy_data()

app = FastAPI(title="Flodo AI Planner API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/tasks", response_model=List[schemas.Task])
def read_tasks(
    status: Optional[models.TaskStatus] = None,
    search: Optional[str] = None,
    db: Session = Depends(database.get_db)
):
    query = db.query(models.Task)
    
    if status:
        query = query.filter(models.Task.status == status)
    
    if search:
        query = query.filter(models.Task.title.ilike(f"%{search}%"))
        
    return query.all()

@app.get("/tasks/{task_id}", response_model=schemas.Task)
def read_task(task_id: int, db: Session = Depends(database.get_db)):
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@app.post("/tasks", response_model=schemas.Task)
async def create_task(task: schemas.TaskCreate, db: Session = Depends(database.get_db)):
    # Simulate a 2-second delay
    await asyncio.sleep(2)
    
    # Verify blocked_by_id if it exists
    if task.blocked_by_id is not None:
        blocked_by_task = db.query(models.Task).filter(models.Task.id == task.blocked_by_id).first()
        if not blocked_by_task:
            raise HTTPException(status_code=400, detail="Blocked-by task not found")
            
    db_task = models.Task(**task.model_dump())
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@app.put("/tasks/{task_id}", response_model=schemas.Task)
async def update_task(task_id: int, task: schemas.TaskUpdate, db: Session = Depends(database.get_db)):
    # Simulate a 2-second delay
    await asyncio.sleep(2)
    
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
        
    if task.blocked_by_id is not None:
        if task.blocked_by_id == task_id:
            raise HTTPException(status_code=400, detail="A task cannot block itself")
        blocked_by_task = db.query(models.Task).filter(models.Task.id == task.blocked_by_id).first()
        if not blocked_by_task:
            raise HTTPException(status_code=400, detail="Blocked-by task not found")
            
    # Check if a recurring task is being marked as Done
    was_done = db_task.status == models.TaskStatus.DONE
    will_be_done = task.status == models.TaskStatus.DONE
    should_duplicate = not was_done and will_be_done and task.recurrence_interval in ("Daily", "Weekly")
            
    for key, value in task.model_dump().items():
        setattr(db_task, key, value)
        
    db.commit()
    db.refresh(db_task)
    
    # Generate duplicate if recurring
    if should_duplicate:
        interval_days = 1 if task.recurrence_interval == "Daily" else 7
        new_due_date = db_task.due_date + timedelta(days=interval_days)
        new_task = models.Task(
            title=db_task.title,
            description=db_task.description,
            due_date=new_due_date,
            status=models.TaskStatus.TODO,
            blocked_by_id=None,
            recurrence_interval=db_task.recurrence_interval
        )
        db.add(new_task)
        db.commit()
        
    return db_task

@app.delete("/tasks/{task_id}")
async def delete_task(task_id: int, db: Session = Depends(database.get_db)):
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
        
    # Optional: Handle tasks that are blocked by this task (e.g., set blocked_by_id to Null)
    db.query(models.Task).filter(models.Task.blocked_by_id == task_id).update({models.Task.blocked_by_id: None})
    
    db.delete(db_task)
    db.commit()
    return {"message": "Task deleted successfully"}

class AITaskRequest(BaseModel):
    prompt: str

class AIPolishRequest(BaseModel):
    title: str
    description: str

class AIPolishResponse(BaseModel):
    title: str
    description: str

@app.post("/tasks/ai/generate", response_model=List[schemas.Task])
async def generate_ai_tasks(req: AITaskRequest, db: Session = Depends(database.get_db)):
    if not os.getenv("GEMINI_API_KEY"):
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY environment variable is missing on the server.")
        
    client = genai.Client()
    prompt_text = f"""
    You are an AI Task Planner. Based on the user prompt: "{req.prompt}", 
    generate a JSON list of 3 structured tasks. Each task must have exactly these keys:
    - title: string
    - description: string
    - due_date: ISO 8601 string (e.g. 2024-05-10T12:00:00Z). Assume today is {datetime.now().isoformat()}
    - status: Exactly "To-Do"
    - recurrence_interval: null
    Return ONLY a valid JSON array of objects.
    """
    
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt_text,
    )
    
    try:
        # Strip markdown code blocks if any
        json_str = response.text.strip()
        if json_str.startswith("```json"):
            json_str = json_str[7:-3]
        elif json_str.startswith("```"):
            json_str = json_str[3:-3]
            
        tasks_data = json.loads(json_str)
        created_tasks = []
        for t in tasks_data:
            # Safely create db models
            t['status'] = models.TaskStatus.TODO
            t['blocked_by_id'] = None
            db_task = models.Task(**t)
            db.add(db_task)
            created_tasks.append(db_task)
            
        db.commit()
        for task in created_tasks:
            db.refresh(task)
            
        return created_tasks
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"AI parsing failed: {str(e)}\nResponse: {response.text}")

@app.post("/tasks/ai/polish", response_model=AIPolishResponse)
async def polish_task_text(req: AIPolishRequest):
    if not os.getenv("GEMINI_API_KEY"):
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY environment variable is missing on the server.")
        
    client = genai.Client()
    prompt_text = f"""
    You are an AI Text Polisher. Please improve the following task title and description to make it professional, clear, and actionable.
    Title: {req.title}
    Description: {req.description}

    Return ONLY a valid JSON object with EXACTLY these two keys:
    "title": "the polished title"
    "description": "the polished description"
    """
    
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt_text,
    )
    
    try:
        json_str = response.text.strip()
        if json_str.startswith("```json"):
            json_str = json_str[7:-3]
        elif json_str.startswith("```"):
            json_str = json_str[3:-3]
            
        data = json.loads(json_str)
        return AIPolishResponse(title=data.get("title", req.title), description=data.get("description", req.description))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI polishing failed: {str(e)}\nResponse: {response.text}")

