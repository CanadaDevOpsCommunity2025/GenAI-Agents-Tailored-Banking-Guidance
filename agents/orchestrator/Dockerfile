FROM python:3.11-slim

WORKDIR /app

RUN pip install redis

COPY orchestrator.py .

CMD ["python", "orchestrator.py"]
