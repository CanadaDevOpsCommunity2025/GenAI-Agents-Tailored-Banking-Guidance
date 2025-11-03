#!/bin/bash

# Setup script for GenAI Agents Tailored Banking Guidance project

echo "Creating project directories..."

# Create directories
mkdir -p gateway
mkdir -p agents/agent1
mkdir -p agents/agent2
mkdir -p mocks
mkdir -p frontend
mkdir -p monitoring
mkdir -p .github/workflows

echo "Creating placeholder files..."

# gateway files
cat > gateway/Dockerfile <<EOF
# Gateway Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "start"]
EOF

cat > gateway/package.json <<EOF
{
  "name": "gateway",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  }
}
EOF

cat > gateway/index.js <<EOF
console.log("Gateway service running...");
EOF

# agents/agent1 files
cat > agents/agent1/Dockerfile <<EOF
# Agent1 Dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "agent1.py"]
EOF

cat > agents/agent1/requirements.txt <<EOF
# Agent1 Python dependencies
flask
openai
EOF

cat > agents/agent1/agent1.py <<EOF
print("Agent1 service running...")
EOF

# agents/agent2 files
cat > agents/agent2/Dockerfile <<EOF
# Agent2 Dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "agent2.py"]
EOF

cat > agents/agent2/requirements.txt <<EOF
# Agent2 Python dependencies
flask
openai
EOF

cat > agents/agent2/agent2.py <<EOF
print("Agent2 service running...")
EOF

# mocks files
cat > mocks/Dockerfile <<EOF
# Mocks Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "start"]
EOF

cat > mocks/package.json <<EOF
{
  "name": "mocks",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  }
}
EOF

cat > mocks/index.js <<EOF
console.log("Mocks service running...");
EOF

# frontend files
cat > frontend/Dockerfile <<EOF
# Frontend Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]
EOF

cat > frontend/package.json <<EOF
{
  "name": "frontend",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "dev": "vite"
  }
}
EOF

cat > frontend/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>GenAI Agents Frontend</title>
</head>
<body>
<div id="app">Welcome to GenAI Agents Frontend</div>
<script type="module" src="/main.js"></script>
</body>
</html>
EOF

cat > frontend/main.js <<EOF
console.log("Frontend running...");
EOF

# monitoring files
cat > monitoring/Dockerfile <<EOF
# Monitoring Dockerfile
FROM prom/prometheus
COPY prometheus.yml /etc/prometheus/prometheus.yml
EOF

cat > monitoring/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'gateway'
    static_configs:
      - targets: ['gateway:3000']
  - job_name: 'agent1'
    static_configs:
      - targets: ['agent1:5000']
  - job_name: 'agent2'
    static_configs:
      - targets: ['agent2:5000']
EOF

# .github/workflows files
cat > .github/workflows/ci.yml <<EOF
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 18
      - name: Install dependencies and build gateway
        working-directory: ./gateway
        run: |
          npm install
          npm run build || echo "No build script"
      - name: Install dependencies and test agents
        run: |
          echo "Add agent tests here"
EOF

# docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  gateway:
    build: ./gateway
    ports:
      - "3000:3000"
    env_file:
      - .env
  agent1:
    build: ./agents/agent1
    ports:
      - "5001:5000"
    env_file:
      - .env
  agent2:
    build: ./agents/agent2
    ports:
      - "5002:5000"
    env_file:
      - .env
  mocks:
    build: ./mocks
    ports:
      - "4000:4000"
  frontend:
    build: ./frontend
    ports:
      - "8080:8080"
  monitoring:
    build: ./monitoring
    ports:
      - "9090:9090"
EOF

# .env.example
cat > .env.example <<EOF
# Environment variables example

OPENAI_API_KEY=your_openai_api_key_here
DATABASE_URL=your_database_url_here
EOF

echo "Project setup complete!"
echo "Directory structure:"
tree -L 3

exit 0
