# 📊 Log Aggregation with ELK Stack

## 🎯 Overview
ELK stack is my go-to solution for centralized logging in distributed systems. Here's why:
- Single source of truth for all application logs
- Real-time log streaming and analysis
- Powerful search and visualization capabilities
- Scalable architecture that grows with your needs

## 🐳 Quick Setup with Docker

### Prerequisites
- Docker & Docker Compose
- At least 4GB of free RAM (ELK can be hungry!)
- Basic understanding of logging concepts

### 🚀 Starting the Stack
```bash
# Start the stack
docker-compose up -d

# Check if all services are running
docker-compose ps
```

### 🔍 Verifying the Setup
1. Check Elasticsearch: `curl http://localhost:9200`
2. Access Kibana: Open `http://localhost:5601` in your browser
3. Send a test log:
```bash
echo '{"message": "test log", "type": "app_logs", "app": "test"}' | \
nc localhost 5000
```

## 🚧 Next Steps
- Setting up log rotation and cleanup policies
- Configuring Filebeat for log shipping
- Creating Kibana dashboards
- Setting up alerting
- Securing the stack for production

## 🔖 Quick Troubleshooting
- If Elasticsearch won't start, check `vm.max_map_count`:
  ```bash
  sudo sysctl -w vm.max_map_count=262144
  ```
- If Logstash is slow, check the pipeline worker settings
- Watch out for disk space - logs can grow quickly!
