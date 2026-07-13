import os
import uuid
from typing import Optional

import redis
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

app = FastAPI(title="taskflow-api", version="1.0.0")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


class Task(BaseModel):
    title: str
    done: bool = False


class TaskOut(Task):
    id: str


@app.get("/healthz")
def healthz():
    try:
        r.ping()
        return {"status": "ok", "redis": "connected"}
    except redis.RedisError:
        raise HTTPException(status_code=503, detail="redis unavailable")


@app.get("/readyz")
def readyz():
    return {"status": "ready"}


@app.post("/tasks", response_model=TaskOut, status_code=201)
def create_task(task: Task):
    task_id = str(uuid.uuid4())
    r.hset(f"task:{task_id}", mapping={"title": task.title, "done": str(task.done)})
    r.sadd("tasks", task_id)
    return TaskOut(id=task_id, **task.model_dump())


@app.get("/tasks", response_model=list[TaskOut])
def list_tasks():
    tasks = []
    for task_id in r.smembers("tasks"):
        data = r.hgetall(f"task:{task_id}")
        if data:
            tasks.append(TaskOut(id=task_id, title=data["title"], done=data["done"] == "True"))
    return tasks


@app.get("/tasks/{task_id}", response_model=TaskOut)
def get_task(task_id: str):
    data = r.hgetall(f"task:{task_id}")
    if not data:
        raise HTTPException(status_code=404, detail="task not found")
    return TaskOut(id=task_id, title=data["title"], done=data["done"] == "True")


@app.patch("/tasks/{task_id}", response_model=TaskOut)
def update_task(task_id: str, done: Optional[bool] = None, title: Optional[str] = None):
    key = f"task:{task_id}"
    if not r.exists(key):
        raise HTTPException(status_code=404, detail="task not found")
    if done is not None:
        r.hset(key, "done", str(done))
    if title is not None:
        r.hset(key, "title", title)
    data = r.hgetall(key)
    return TaskOut(id=task_id, title=data["title"], done=data["done"] == "True")


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: str):
    key = f"task:{task_id}"
    if not r.exists(key):
        raise HTTPException(status_code=404, detail="task not found")
    r.delete(key)
    r.srem("tasks", task_id)
