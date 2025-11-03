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
