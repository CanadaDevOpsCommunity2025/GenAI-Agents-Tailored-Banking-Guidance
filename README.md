# GenAI Agents empowering customers with transparent, tailored banking guidance
Canada DevOps Community of Practice Hackathon Toronto - Team 5 

Project Name - GenAI Agents empowering customers with transparent, tailored banking guidance

Team Mentor -

Participant Names - 
     Team Leaders - Path Parab
     
     Team Members - Daniel Nguyen, Kacper Burza, Anthony Spiteri, Onimisi Ayira

---

## Repository Structure

| Directory | Purpose |
|------------|----------|
| `gateway/` | FastAPI service that acts as the entry point and routes requests to the message queue. |
| `agents/` | Contains all GenAI agents such as orchestrator, conversation, KYC, advisor, and audit. |
| `mocks/` | Mock services and datasets for KYC and product recommendation testing. |
| `frontend/` | Simple React or Streamlit UI for interacting with the system. |
| `monitoring/` | Prometheus and Grafana configuration files for metrics and dashboards. |
| `.github/workflows/` | CI/CD pipelines for building and deploying containers. |
| `.env.example` | Example environment configuration for development. |
| `docker-compose.yml` | Container orchestration setup for local development. |

Each folder is modular to allow parallel development across team members.
