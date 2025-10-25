# DevOps Intern Stage 2 – Blue/Green Deployment with Nginx Upstreams

This project implements a **Blue/Green deployment strategy** using **Nginx** as a reverse proxy and two **Node.js service instances** (Blue and Green) running in Docker containers.

It supports:
- ✅ Automatic health-based failover (Blue → Green)
- ✅ Manual active pool toggle via environment variable
- ✅ Zero downtime during failover
- ✅ Header forwarding (`X-App-Pool`, `X-Release-Id`)
- ✅ Fully parameterized configuration for CI/CD

---

## 🧩 Overview

Two identical application containers (`Blue` and `Green`) expose:
- `GET /version` → returns service metadata and headers
- `GET /healthz` → health endpoint
- `POST /chaos/start?mode=error|timeout` → simulate downtime
- `POST /chaos/stop` → recover from chaos

Nginx sits in front as the single public entrypoint:
- Routes all client traffic to the **active pool** (`Blue` by default)
- On failure, automatically retries the request to the **backup pool**
- Forwards all application headers transparently

---

## 🏗️ Architecture

```

```
               ┌────────────────────┐
               │     Nginx Proxy    │  ← :8080
               └─────────┬──────────┘
                         │
      ┌──────────────────┴──────────────────┐
      │                                     │
```

┌──────────────────┐                 ┌──────────────────┐
│   Blue Service    │ :8081          │   Green Service   │ :8082
│ X-App-Pool: blue  │                │ X-App-Pool: green │
│ X-Release-Id: v1  │                │ X-Release-Id: v2  │
└──────────────────┘                 └──────────────────┘

````


## **Getting Started**

### **Prerequisites**

* Docker and Docker Compose
* Nginx

### **Installation**

1. Clone the repository:

```bash
git clone https://github.com/Katsayal/hng-mobile-stage1-inventoryapp.git
cd blue-green-nginx
```

## ⚙️ Environment Configuration

All runtime configuration is managed via a `.env` file.

Example:

```bash
BLUE_IMAGE=docker image
GREEN_IMAGE=docker image
ACTIVE_POOL=blue
RELEASE_ID_BLUE=v1.0.1
RELEASE_ID_GREEN=v1.0.2
PORT=3000
````

### Variables Explained

| Variable           | Description                                      |
| ------------------ | ------------------------------------------------ |
| `BLUE_IMAGE`       | Docker image for the Blue service                |
| `GREEN_IMAGE`      | Docker image for the Green service               |
| `ACTIVE_POOL`      | Controls default active pool (`blue` or `green`) |
| `RELEASE_ID_BLUE`  | Release ID returned by Blue                      |
| `RELEASE_ID_GREEN` | Release ID returned by Green                     |
| `PORT`             | Internal application port                        |

---

## 🐳 Docker Compose Setup

### Services

| Service     | Port   | Description                              |
| ----------- | ------ | ---------------------------------------- |
| `nginx`     | `8080` | Public load balancer with failover logic |
| `app_blue`  | `8081` | Primary Node.js instance                 |
| `app_green` | `8082` | Backup Node.js instance                  |

### Bring Up the Stack

```bash
docker compose up -d
```

### Check Container Status

```bash
docker compose ps
```

---

## 🌐 Endpoints

| Endpoint       | Description                              | Example                                                     |
| -------------- | ---------------------------------------- | ----------------------------------------------------------- |
| `/version`     | Returns current pool info and release ID | `curl http://localhost:8080/version`                        |
| `/healthz`     | Upstream health check                    | `curl http://localhost:8080/healthz`                        |
| `/chaos/start` | Induce simulated downtime                | `curl -X POST http://localhost:8081/chaos/start?mode=error` |
| `/chaos/stop`  | Recover service                          | `curl -X POST http://localhost:8081/chaos/stop`             |

---

## 🔄 Failover Demonstration

### 1️⃣ Check Baseline (Blue Active)

```bash
curl -i http://localhost:8080/version
```

Expected:

```
X-App-Pool: blue
X-Release-Id: v1.0.1
```

### 2️⃣ Trigger Chaos on Blue

```bash
curl -X POST http://localhost:8081/chaos/start?mode=error
```

### 3️⃣ Verify Automatic Failover

```bash
curl -i http://localhost:8080/version
```

Expected:

```
X-App-Pool: green
X-Release-Id: v1.0.2
```

### 4️⃣ Stop Chaos (Return to Normal)

```bash
curl -X POST http://localhost:8081/chaos/stop
```

After a few seconds:

```bash
curl -i http://localhost:8080/version
# -> X-App-Pool: blue
```

All requests remain **HTTP 200 OK**, ensuring zero downtime.

---

## 🔁 Manual Active Pool Toggle

You can switch which pool is *primary* using the `.env` file:

```bash
ACTIVE_POOL=green
```

Then restart or reload Nginx:

```bash
docker compose up -d nginx
```

This allows **manual promotion/demotion** of services without changing code.

---

## 🧠 Technical Highlights

* **Nginx upstream failover**

  ```nginx
  upstream app_upstream {
    server app_blue:3000 max_fails=1 fail_timeout=3s;
    server app_green:3000 backup;
  }
  ```

* **Retry logic**

  ```nginx
  proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
  proxy_next_upstream_tries 2;
  ```

* **Header forwarding**

  ```nginx
  proxy_pass_header X-App-Pool;
  proxy_pass_header X-Release-Id;
  proxy_pass_request_headers on;
  ```

* **Health-driven switch:** Nginx retries instantly to backup if Blue times out or fails.

---

## 🧪 Verification Script

A helper script (`verify.sh`) automates testing of failover logic


## 🧹 Cleanup

Stop and remove all containers:

```bash
docker compose down
```

---

## 📦 Files Included

```
blue-green-nginx/
├── docker-compose.yml
├── .env
├── README.md
├── verify.sh
└── nginx/
    ├── nginx.conf.template
    └── entrypoint.sh
```

---

## 🏁 Summary

| Capability                         | Status |
| ---------------------------------- | ------ |
| Blue active by default             | ✅      |
| Automatic failover to Green        | ✅      |
| 0 failed requests during chaos     | ✅      |
| Header forwarding                  | ✅      |
| Manual toggle via `.env`           | ✅      |
| Fully parameterized Docker Compose | ✅      |

