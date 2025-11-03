FROM python:3.11-slim

WORKDIR /app

RUN pip install redis

COPY audit.py .

CMD ["python", "audit.py"]
