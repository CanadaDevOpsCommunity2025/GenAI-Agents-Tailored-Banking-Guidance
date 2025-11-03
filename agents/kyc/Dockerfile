FROM python:3.11-slim

WORKDIR /app

RUN pip install redis

COPY kyc.py .

CMD ["python", "kyc.py"]
