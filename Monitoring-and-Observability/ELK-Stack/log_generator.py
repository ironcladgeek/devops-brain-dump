import json
import logging
import random
import socket
import time
from datetime import datetime

# List of sample log messages and events
SAMPLE_EVENTS = [
    "User login attempt",
    "Database query executed",
    "API request received",
    "Cache miss",
    "File upload completed",
    "Background job started",
    "Email notification sent",
    "Payment processing initiated",
]

LOG_LEVELS = ["INFO", "WARNING", "ERROR", "DEBUG"]
STATUS_CODES = [200, 201, 400, 401, 403, 404, 500, 503]
USER_IDS = list(range(1, 1001))  # User IDs from 1 to 1000


def generate_random_log():
    """Generate a random log entry"""
    timestamp = datetime.utcnow().isoformat()
    event = random.choice(SAMPLE_EVENTS)
    level = random.choice(LOG_LEVELS)

    log_data = {
        "timestamp": timestamp,
        "level": level,
        "event": event,
        "details": {
            "user_id": random.choice(USER_IDS),
            "status_code": random.choice(STATUS_CODES),
            "response_time": round(random.uniform(0.1, 2.0), 3),
            "source_ip": f"192.168.{random.randint(1,255)}.{random.randint(1,255)}",
        },
    }

    # Add some conditional extra fields based on the event type
    if "API request" in event:
        log_data["details"]["endpoint"] = (
            f"/api/v1/{random.choice(['users', 'products', 'orders'])}"
        )
        log_data["details"]["method"] = random.choice(["GET", "POST", "PUT", "DELETE"])
    elif "Database" in event:
        log_data["details"]["query_time"] = round(random.uniform(0.01, 0.5), 3)
        log_data["details"]["rows_affected"] = random.randint(1, 1000)

    return log_data


def send_log(host="localhost", port=5000):
    """Send log to Logstash via TCP"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.connect((host, port))
        while True:
            log_entry = generate_random_log()
            log_entry["type"] = "app_logs"  # Add type field for Logstash filtering
            message = json.dumps(log_entry) + "\n"
            sock.send(message.encode())

            # Random sleep between 1 and 5 seconds
            time.sleep(random.uniform(1, 5))

    except Exception as e:
        logging.error(f"Error sending log: {e}")
    finally:
        sock.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    logging.info("Starting log generator...")

    # Add retry logic for container orchestration
    while True:
        try:
            send_log(host="logstash")  # Use service name from docker-compose
            time.sleep(5)  # Wait before retrying
        except Exception as e:
            logging.error(f"Connection failed: {e}")
            time.sleep(5)  # Wait before retrying
