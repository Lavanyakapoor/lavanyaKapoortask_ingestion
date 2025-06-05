from flask import Flask, request, jsonify
from threading import Thread, Lock
from time import sleep
from uuid import uuid4
from collections import deque
from datetime import datetime

app = Flask(__name__)

tasks = {}
task_queue = deque()
queue_lock = Lock()
priority_map = {"HIGH": 1, "MEDIUM": 2, "LOW": 3}
is_processing = False

def worker():
    global is_processing
    if queue_lock.acquire(blocking=False):
        if is_processing:
            queue_lock.release()
            return
        is_processing = True
        queue_lock.release()

    while task_queue:
        if queue_lock.acquire():
            sorted_queue = sorted(task_queue, key=lambda x: (x[0], x[1]))
            task_queue.clear()
            task_queue.extend(sorted_queue)
            priority, timestamp, task_id = task_queue.popleft()
            queue_lock.release()

        current_task = tasks[task_id]

        for batch in current_task["batches"]:
            batch["status"] = "triggered"
            current_task["status"] = "triggered"
            sleep(5)  # simulate work
            batch["status"] = "completed"

        current_task["status"] = "completed"

    if queue_lock.acquire():
        is_processing = False
        queue_lock.release()

@app.route('/')
def index():
    return "Flask API is running now."

@app.route('/ingest', methods=['POST'])
def add_task():
    data = request.get_json()
    if not data or "ids" not in data or "priority" not in data:
        return jsonify({"error": "Request must include 'ids' and 'priority'"}), 400

    ids_list = data["ids"]
    priority = data["priority"].upper()
    if priority not in priority_map:
        return jsonify({"error": "Priority must be HIGH, MEDIUM, or LOW"}), 400

    task_id = str(uuid4())
    batches = []

    # Create batches of 3 IDs max
    for i in range(0, len(ids_list), 3):
        batch_ids = ids_list[i:i+3]
        batches.append({
            "batch_id": str(uuid4()),
            "ids": batch_ids,
            "status": "pending"
        })

    task_info = {
        "id": task_id,
        "status": "pending",
        "priority": priority,
        "created_at": datetime.utcnow().timestamp(),
        "batches": batches
    }
    tasks[task_id] = task_info
    task_queue.append((priority_map[priority], task_info["created_at"], task_id))

    thread = Thread(target=worker, daemon=True)
    thread.start()
    return jsonify({"ingestion_id": task_id})

@app.route('/status/<task_id>', methods=['GET'])
def task_status(task_id):
    task = tasks.get(task_id)
    if not task:
        return jsonify({"error": "Task ID not found"}), 404

    batch_states = [batch["status"] for batch in task["batches"]]

    overall_status = "yet_to_start"
    if all(state == "completed" for state in batch_states):
        overall_status = "completed"
    elif any(state == "triggered" for state in batch_states):
        overall_status = "triggered"

    return jsonify({
        "ingestion_id": task_id,
        "status": overall_status,
        "batches": task["batches"]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)