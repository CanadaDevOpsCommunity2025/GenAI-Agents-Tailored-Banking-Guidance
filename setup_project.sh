#!/bin/bash

# Create directories
mkdir -p gateway
mkdir -p agents/orchestrator
mkdir -p agents/conversation
mkdir -p agents/kyc
mkdir -p agents/advisor
mkdir -p agents/audit
mkdir -p mocks
mkdir -p frontend
mkdir -p monitoring
mkdir -p .github/workflows

# Create Docker Compose file
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  redis:
    image: redis:7
    ports:
      - "6379:6379"

  gateway:
    build: ./gateway
    ports:
      - "8000:8000"
    depends_on:
      - redis

  orchestrator:
    build: ./agents/orchestrator
    depends_on:
      - redis
    deploy:
      replicas: 1

  conversation:
    build: ./agents/conversation
    depends_on:
      - redis
    deploy:
      replicas: 2

  kyc:
    build: ./agents/kyc
    depends_on:
      - redis
    deploy:
      replicas: 2

  advisor:
    build: ./agents/advisor
    depends_on:
      - redis
    deploy:
      replicas: 2

  audit:
    build: ./agents/audit
    depends_on:
      - redis
    deploy:
      replicas: 1
EOF

# Create .env.example
cat > .env.example <<EOF
REDIS_URL=redis://redis:6379/0
EOF

# Create Prometheus config
cat > monitoring/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'gateway'
    static_configs:
      - targets: ['gateway:8000']

  - job_name: 'agents'
    static_configs:
      - targets: ['orchestrator:8001', 'conversation:8002', 'kyc:8003', 'advisor:8004', 'audit:8005']
EOF

# Create Gateway FastAPI service
mkdir -p gateway
cat > gateway/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

RUN pip install fastapi uvicorn redis

COPY main.py .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

cat > gateway/main.py <<EOF
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
EOF

# Create agent templates using Redis Pub/Sub

# Orchestrator agent
mkdir -p agents/orchestrator
cat > agents/orchestrator/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

RUN pip install redis

COPY orchestrator.py .

CMD ["python", "orchestrator.py"]
EOF

cat > agents/orchestrator/orchestrator.py <<EOF
import redis
import os
import json
import time

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
r = redis.from_url(redis_url)
pubsub = r.pubsub()
pubsub.subscribe("orchestrator")

def publish_next_step(channel, message):
    r.publish(channel, json.dumps(message))

print("Orchestrator started and listening...")

for message in pubsub.listen():
    if message['type'] != 'message':
        continue
    data = json.loads(message['data'])
    task_id = data["task_id"]
    user_id = data["user_id"]
    step = data.get("step")

    if step == "start":
        print(f"Orchestrator: Starting onboarding for user {user_id}")
        # Trigger conversation agent
        publish_next_step("conversation", {"task_id": task_id, "user_id": user_id, "step": "conversation_start"})

    elif step == "conversation_done":
        print(f"Orchestrator: Conversation done for user {user_id}")
        # Trigger KYC agent
        publish_next_step("kyc", {"task_id": task_id, "user_id": user_id, "step": "kyc_start"})

    elif step == "kyc_done":
        print(f"Orchestrator: KYC done for user {user_id}")
        # Trigger advisor agent
        publish_next_step("advisor", {"task_id": task_id, "user_id": user_id, "step": "advisor_start"})

    elif step == "advisor_done":
        print(f"Orchestrator: Advisor done for user {user_id}")
        # Trigger audit agent
        publish_next_step("audit", {"task_id": task_id, "user_id": user_id, "step": "audit_start"})

    elif step == "audit_done":
        print(f"Orchestrator: Audit done for user {user_id}")
        print(f"Onboarding completed for user {user_id}")
EOF

# Conversation agent
mkdir -p agents/conversation
cat > agents/conversation/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

RUN pip install redis

COPY conversation.py .

CMD ["python", "conversation.py"]
EOF

cat > agents/conversation/conversation.py <<EOF
import redis
import os
import json
import time

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
r = redis.from_url(redis_url)
pubsub = r.pubsub()
pubsub.subscribe("conversation")

def publish_next_step(channel, message):
    r.publish(channel, json.dumps(message))

print("Conversation agent started and listening...")

for message in pubsub.listen():
    if message['type'] != 'message':
        continue
    data = json.loads(message['data'])
    task_id = data["task_id"]
    user_id = data["user_id"]
    step = data.get("step")

    if step == "conversation_start":
        print(f"Conversation: Processing conversation for user {user_id}")
        time.sleep(2)  # Simulate conversation processing
        publish_next_step("orchestrator", {"task_id": task_id, "user_id": user_id, "step": "conversation_done"})
EOF

# KYC agent
mkdir -p agents/kyc
cat > agents/kyc/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

RUN pip install redis

COPY kyc.py .

CMD ["python", "kyc.py"]
EOF

cat > agents/kyc/kyc.py <<EOF
import redis
import os
import json
import time

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
r = redis.from_url(redis_url)
pubsub = r.pubsub()
pubsub.subscribe("kyc")

def publish_next_step(channel, message):
    r.publish(channel, json.dumps(message))

print("KYC agent started and listening...")

for message in pubsub.listen():
    if message['type'] != 'message':
        continue
    data = json.loads(message['data'])
    task_id = data["task_id"]
    user_id = data["user_id"]
    step = data.get("step")

    if step == "kyc_start":
        print(f"KYC: Processing KYC for user {user_id}")
        time.sleep(2)  # Simulate KYC processing
        publish_next_step("orchestrator", {"task_id": task_id, "user_id": user_id, "step": "kyc_done"})
EOF

# Advisor agent
mkdir -p agents/advisor
cat > agents/advisor/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

RUN pip install redis

COPY advisor.py .

CMD ["python", "advisor.py"]
EOF

cat > agents/advisor/advisor.py <<EOF
import redis
import os
import json
import time

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
r = redis.from_url(redis_url)
pubsub = r.pubsub()
pubsub.subscribe("advisor")

def publish_next_step(channel, message):
    r.publish(channel, json.dumps(message))

print("Advisor agent started and listening...")

for message in pubsub.listen():
    if message['type'] != 'message':
        continue
    data = json.loads(message['data'])
    task_id = data["task_id"]
    user_id = data["user_id"]
    step = data.get("step")

    if step == "advisor_start":
        print(f"Advisor: Processing advice for user {user_id}")
        time.sleep(2)  # Simulate advisor processing
        publish_next_step("orchestrator", {"task_id": task_id, "user_id": user_id, "step": "advisor_done"})
EOF

# Audit agent
mkdir -p agents/audit
cat > agents/audit/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

RUN pip install redis

COPY audit.py .

CMD ["python", "audit.py"]
EOF

cat > agents/audit/audit.py <<EOF
import redis
import os
import json
import time

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
r = redis.from_url(redis_url)
pubsub = r.pubsub()
pubsub.subscribe("audit")

def publish_next_step(channel, message):
    r.publish(channel, json.dumps(message))

print("Audit agent started and listening...")

for message in pubsub.listen():
    if message['type'] != 'message':
        continue
    data = json.loads(message['data'])
    task_id = data["task_id"]
    user_id = data["user_id"]
    step = data.get("step")

    if step == "audit_start":
        print(f"Audit: Processing audit for user {user_id}")
        time.sleep(2)  # Simulate audit processing
        publish_next_step("orchestrator", {"task_id": task_id, "user_id": user_id, "step": "audit_done"})
EOF

echo "Setup complete!

To start the system, run:
  docker-compose up --build

To scale agents, for example conversation agent, run:
  docker-compose up --scale conversation=3 --scale kyc=2 --scale advisor=2 --scale orchestrator=1 --scale audit=1 --build

This will start multiple instances of each agent for scalability."
