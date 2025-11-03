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
