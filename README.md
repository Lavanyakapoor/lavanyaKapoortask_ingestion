Ingestion API by Lavanya Kapoor
it is an API made using flask that accepts a list of IDs and a priority (HIGH, MEDIUM, LOW), splitting IDs into batches of up to 3.

It provides status updates for tasks and their batches (yet_to_start, triggered, completed).

The priority of the tasks is handled with the order of high>medium>low.

Design Choices :
Flask is used here because it aloows for easy development and fast deployment.
Tasks are stored in a deque and sorted by priority and timestamp for fair scheduling.
Task status is derived from batch statuses:
yet_to_start: All batches are yet_to_start.
triggered: At least one batch is triggered.
completed: All batches are completed.

Local setup:
1. clone the github repository 
git clone https://github.com/Lavanyakapoor/lavanyaKapoortask_ingestion
cd task-ingestion-api
2. Create a virtual environment:
python -m venv venv
source venv/bin/activate 
3. install dependencies
pip install -r requirements.txt
4. run application
python app.py

<img width="630" alt="Screenshot 2025-06-05 at 11 29 30 AM" src="https://github.com/user-attachments/assets/3e3645a0-c12c-480e-babe-dcbfa4c6a7fd" />

Repository
The source code is hosted at: https://github.com/Lavanyakapoor/lavanyaKapoortask_ingestion

Deployed URL
The application is deployed at: https://e94fb036-1fcf-48b3-9772-58c65bd020f0-00-1qhuy96r5k581.kirk.replit.dev/.

