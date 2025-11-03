from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import redis
import os
import json
import uuid

app = FastAPI()

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
r = redis.from_url(redis_url)

class OnboardingRequest(BaseModel):
    user_id: str

@app.post("/start_onboarding")
async def start_onboarding(request: OnboardingRequest):
    task_id = str(uuid.uuid4())
    message = {
        "task_id": task_id,
        "user_id": request.user_id,
        "step": "start"
    }
    r.publish("orchestrator", json.dumps(message))
    return {"message": "Onboarding started", "task_id": task_id}
