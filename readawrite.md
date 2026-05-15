# อธิบายโปรเจกต์ Monkey Pop Pop แบบไล่ตาม Flow การทำงาน

เอกสารนี้อธิบายโปรเจกต์ **Monkey Pop Pop** โดยไล่ตามลำดับการทำงานจริงของระบบ ตั้งแต่ผู้พัฒนาเขียนโค้ด, build เป็น Docker image, deploy ขึ้น Kubernetes, ผู้เล่นเข้าใช้งานเกม, backend บันทึกคะแนนลง Redis, ไปจนถึง Prometheus และ Grafana ที่ใช้ monitoring ระบบ

---

## 1. ภาพรวมของระบบ

โปรเจกต์นี้เป็นเว็บเกมแบบ Full-stack มีส่วนประกอบหลักดังนี้

| ส่วนของระบบ | โฟลเดอร์/ไฟล์ที่เกี่ยวข้อง | หน้าที่ |
|---|---|---|
| Frontend | `frontend/` | หน้าเว็บเกมที่ผู้เล่นใช้งาน |
| Backend | `backend/` | API สำหรับรับคะแนน ดึง leaderboard และส่ง metrics |
| Database | Redis | เก็บคะแนน leaderboard |
| Container | `Dockerfile`, `Docker-compose.yml` | สร้างและรันระบบในรูปแบบ container |
| CI/CD | `jenkins/` | build, push image และ deploy อัตโนมัติ |
| Infrastructure | `Terraform/` | สร้าง namespace, ConfigMap, Secret และ Redis |
| Deployment | `ansible/`, `k8s/` | deploy app เข้า Kubernetes |
| Monitoring | `prometheus/`, `grafana/`, `k8s/monitoring*.yaml` | เก็บ metrics และแสดง dashboard |

Flow รวมของระบบคือ

```text
Developer
  -> GitHub
  -> Jenkins
  -> Docker Build
  -> Docker Hub
  -> Terraform
  -> Ansible
  -> Kubernetes
  -> Frontend / Backend / Redis
  -> Prometheus
  -> Grafana
```

---

## 2. เริ่มจาก Source Code ของแอป

ส่วนแรกของโปรเจกต์คือ source code ของเกม แบ่งเป็น `frontend/` และ `backend/`

### 2.1 Frontend: หน้าเกมที่ผู้เล่นเห็น

โฟลเดอร์ `frontend/` คือหน้าเว็บเกม Monkey Pop Pop

```text
frontend/
├── index.html
├── Dockerfile
├── background.png
├── monkey1.png
├── monkey2.png
└── chieuk-thinking-289286.mp3
```

ไฟล์หลักคือ `frontend/index.html` ภายในไฟล์นี้รวมทั้ง HTML, CSS และ JavaScript ไว้ด้วยกัน

หน้าที่ของ `index.html` คือ

- แสดงหน้าเริ่มเกมให้ผู้เล่นกรอกชื่อ
- แสดงตัวจับเวลา 30 วินาที
- แสดงคะแนนระหว่างเล่น
- แสดง Top 5 ranking
- เปลี่ยนรูปลิงตอนกด
- เล่นเสียงตอนกด
- ดึง leaderboard จาก backend
- ส่งคะแนนไป backend หลังจบเกม

ไฟล์ asset ที่ frontend ใช้ ได้แก่

- `background.png` เป็นภาพพื้นหลังของเกม
- `monkey1.png` เป็นภาพลิงสถานะปกติ
- `monkey2.png` เป็นภาพลิงตอนถูกกด
- `chieuk-thinking-289286.mp3` เป็นเสียงตอนผู้เล่นกด

ใน frontend มีการกำหนด URL ของ backend ไว้ด้วย ถ้ารันบน Kubernetes จะเรียก backend ผ่าน port `30002` แต่ถ้ารัน local จะเรียก `http://localhost:3001`

### 2.2 Backend: API สำหรับคะแนนและ leaderboard

โฟลเดอร์ `backend/` คือส่วน API ของเกม

```text
backend/
├── server.js
├── package.json
└── Dockerfile
```

ไฟล์หลักคือ `backend/server.js` ทำหน้าที่เปิด Express server ที่ port `3001`

API สำคัญใน backend มี 3 endpoint

| Method | Endpoint | หน้าที่ |
|---|---|---|
| `POST` | `/api/score` | รับคะแนนจาก frontend แล้วบันทึกลง Redis |
| `GET` | `/api/leaderboard` | ดึง Top 5 leaderboard จาก Redis |
| `GET` | `/metrics` | ส่ง metrics ให้ Prometheus ดึงไปเก็บ |

backend ใช้ Redis เป็นฐานข้อมูล โดยเชื่อมต่อผ่านค่า `REDIS_URL`

ก่อนบันทึกคะแนน backend จะตรวจสอบ header `x-api-key` ว่าตรงกับค่า `API_KEY` หรือไม่ ค่าเหล่านี้จะถูกส่งมาจาก Kubernetes ConfigMap และ Secret

ไฟล์ `backend/package.json` ใช้กำหนด dependencies ของ backend เช่น

- `express` สำหรับสร้าง API
- `redis` สำหรับเชื่อมต่อ Redis
- `cors` สำหรับให้ frontend เรียก backend ได้
- `prom-client` สำหรับสร้าง metrics ให้ Prometheus
- `uuid` สำหรับสร้าง id หากต้องใช้

---

## 3. แปลง Source Code เป็น Docker Image

เมื่อมี frontend และ backend แล้ว ขั้นต่อไปคือทำให้แต่ละส่วนกลายเป็น Docker image เพื่อให้รันใน container ได้

### 3.1 Dockerfile ของ Backend

ไฟล์ `backend/Dockerfile` ใช้ build backend image

Flow การทำงานของไฟล์นี้คือ

1. ใช้ base image `node:18-alpine`
2. ตั้ง working directory เป็น `/app`
3. copy `package.json`
4. ติดตั้ง dependencies ด้วย `npm install`
5. copy source code ทั้งหมด
6. เปิด port `3001`
7. สั่งรัน `npm start`

สรุปคือ Dockerfile นี้ทำให้ backend กลายเป็น container ที่เปิด API ได้ที่ port `3001`

### 3.2 Dockerfile ของ Frontend

ไฟล์ `frontend/Dockerfile` ใช้ build frontend image

Flow การทำงานของไฟล์นี้คือ

1. ใช้ base image `nginx:alpine`
2. copy ไฟล์ทั้งหมดใน `frontend/` ไปไว้ที่ `/usr/share/nginx/html/`
3. เปิด port `80`
4. รัน nginx เพื่อ serve หน้าเว็บ

สรุปคือ Dockerfile นี้ทำให้ frontend กลายเป็นเว็บ static ที่เปิดผ่าน nginx

### 3.3 Docker Compose สำหรับทดสอบ Local

ไฟล์ `Docker-compose.yml` ใช้รันระบบหลาย container พร้อมกันบนเครื่อง local

service ที่อยู่ในไฟล์นี้ ได้แก่

- `frontend` รันหน้าเว็บเกม
- `backend` รัน API
- `redis` เก็บ leaderboard
- `prometheus` เก็บ metrics
- `grafana` แสดง dashboard
- `node-exporter` ส่ง metrics ของเครื่อง
- `jenkins` รันระบบ CI/CD
- `k8s-proxy` ช่วย proxy port จาก Kubernetes service

ถ้าต้องการทดสอบระบบแบบ local สามารถใช้ไฟล์นี้เพื่อรันทุกอย่างพร้อมกันได้

---

## 4. Jenkins เริ่มกระบวนการ CI/CD

เมื่อ developer push code ไป GitHub Jenkins จะเริ่ม pipeline เพื่อ build และ deploy ระบบ

โฟลเดอร์ที่เกี่ยวข้องคือ

```text
jenkins/
└── build/
    ├── Jenkinsfile_backend
    └── Jenkinsfile_frountend
```

### 4.1 Jenkins Image

ไฟล์ `Dockerfile.jenkins` ใช้สร้าง Jenkins image ที่ติดตั้งเครื่องมือเพิ่มเติมไว้แล้ว เช่น

- Docker CLI
- Terraform
- kubectl
- Ansible
- Node.js

เหตุผลที่ต้องติดตั้งเครื่องมือเหล่านี้ เพราะ Jenkins ต้องใช้ในการ build image, push image, สร้าง infrastructure และ deploy เข้า Kubernetes

### 4.2 Pipeline ของ Backend

ไฟล์ `jenkins/build/Jenkinsfile_backend` คือ pipeline สำหรับ backend

Flow ของ backend pipeline คือ

1. `Checkout` ดึง source code จาก GitHub
2. `Build` เข้าโฟลเดอร์ `backend` แล้วรัน `npm install`
3. `Test` รันทดสอบแบบจำลอง เช่น เช็ก Node.js version
4. `Docker Build` build image จาก `backend/Dockerfile`
5. `Push Hub` push image ไป Docker Hub ชื่อ `thamonwanfirst/monkeypop-backend`
6. `Deploy` รัน Terraform เพื่อสร้าง resource พื้นฐาน
7. รัน Ansible เพื่อ deploy backend อย่างเดียว ส่วน Redis ถูกดูแลโดย Terraform
8. deploy monitoring stack เช่น Prometheus, Grafana และ kube-state-metrics
9. หลังจบ pipeline ลบ image ในเครื่อง Jenkins และ logout Docker

### 4.3 Pipeline ของ Frontend

ไฟล์ `jenkins/build/Jenkinsfile_frountend` คือ pipeline สำหรับ frontend

Flow ของ frontend pipeline คือ

1. `Checkout` ดึง source code จาก GitHub
2. `Build` ตรวจสอบไฟล์ frontend
3. `Test` เช็กว่า `index.html` มีอยู่จริง
4. `Docker Build` build image จาก `frontend/Dockerfile`
5. `Push Hub` push image ไป Docker Hub ชื่อ `thamonwanfirst/monkeypop-frontend`
6. `Deploy` รัน Terraform เพื่อเตรียม resource พื้นฐาน แล้วรัน Ansible เพื่อ deploy frontend เข้า Kubernetes
7. หลังจบ pipeline ลบ image ในเครื่อง Jenkins และ logout Docker

หมายเหตุ: ชื่อไฟล์ `Jenkinsfile_frountend` สะกดว่า `frountend` แต่ความหมายคือ frontend

---

## 5. Terraform เตรียม Resource พื้นฐานใน Kubernetes

ก่อน deploy แอปต้องมี resource พื้นฐานใน Kubernetes ก่อน เช่น namespace, ConfigMap, Secret และ Redis

โฟลเดอร์ที่เกี่ยวข้องคือ

```text
Terraform/
├── main.tf
├── variables.tf
├── README.md
├── Makefile
├── setup.ps1
├── setup.sh
├── terraform.bat
└── terraform.sh
```

### 5.1 `Terraform/main.tf`

ไฟล์นี้เป็นไฟล์หลักของ Terraform

หน้าที่คือ

- กำหนด Kubernetes provider
- ใช้ kubeconfig ที่ `/var/jenkins_home/.kube/config`
- สร้าง namespace `monkeypop`
- สร้าง ConfigMap `backend-config`
- สร้าง Secret `backend-secret`
- สร้าง Redis PVC `redis-pvc`
- deploy Redis
- สร้าง Redis Service

ConfigMap ใช้เก็บค่า

```text
REDIS_URL=redis://redis:6379
```

Secret ใช้เก็บค่า

```text
API_KEY=monkey-secret-key
```

ค่าเหล่านี้ backend จะนำไปใช้ตอนรันใน Kubernetes

Redis ถูกจัดให้อยู่ใน Terraform เพราะเป็น service พื้นฐานที่ backend ต้องใช้เก็บ leaderboard ไม่ใช่ source code ของ backend โดยตรง

### 5.2 `Terraform/variables.tf`

ไฟล์นี้กำหนดตัวแปรของ Terraform เช่น

- `namespace_name`
- `redis_url`
- `api_key`

ถึงแม้ตอนนี้ใน `main.tf` จะกำหนดค่าหลายอย่างไว้ตรง ๆ แต่ไฟล์ variables ก็มีไว้เพื่อรองรับการปรับค่าในอนาคต

### 5.3 ไฟล์ช่วยรัน Terraform

ไฟล์อื่น ๆ ในโฟลเดอร์ Terraform ใช้ช่วยติดตั้งหรือรัน Terraform

- `Terraform/README.md` อธิบายวิธีใช้ Terraform
- `Terraform/Makefile` รวมคำสั่งลัด เช่น `make init`, `make plan`, `make apply`
- `Terraform/setup.ps1` ติดตั้ง Terraform บน Windows
- `Terraform/setup.sh` ติดตั้ง Terraform บน Linux/macOS
- `Terraform/terraform.bat` ตัวช่วยรัน Terraform บน Windows CMD
- `Terraform/terraform.sh` ตัวช่วยรัน Terraform บน Linux/macOS

---

## 6. Ansible Deploy เฉพาะแอปเข้า Kubernetes

หลังจาก Terraform เตรียม resource พื้นฐานแล้ว Jenkins จะเรียก Ansible เพื่อ deploy application เท่านั้น โดย Ansible จะไม่สร้าง namespace, ConfigMap, Secret หรือ Redis แล้ว

โฟลเดอร์ที่เกี่ยวข้องคือ

```text
ansible/
├── backend/
│   ├── hosts.ini
│   └── deploy_backend.yml
└── frontend/
    ├── hosts.ini
    └── deploy_frontend.yml
```

### 6.1 Ansible Hosts

ไฟล์ `ansible/backend/hosts.ini` และ `ansible/frontend/hosts.ini` มีเนื้อหาเหมือนกัน คือ

```ini
server ansible_host=localhost ansible_connection=local
```

หมายความว่า Ansible จะรันคำสั่งบนเครื่อง local หรือใน Jenkins container ที่ pipeline กำลังทำงาน

### 6.2 Deploy Backend

ไฟล์ `ansible/backend/deploy_backend.yml` ใช้ deploy backend และ Backend Service

Flow ของ playbook นี้คือ

1. deploy backend จำนวน 2 replicas
2. backend ดึง `REDIS_URL` จาก ConfigMap ที่ Terraform สร้างไว้
3. backend ดึง `API_KEY` จาก Secret ที่ Terraform สร้างไว้
4. สร้าง Backend Service แบบ NodePort ที่ port `30002`
5. สั่ง rollout restart เพื่อให้ backend ใช้ image ล่าสุด

ส่วน namespace, ConfigMap, Secret, Redis PVC, Redis Deployment และ Redis Service ถูกย้ายไปให้ Terraform ดูแลทั้งหมด

### 6.3 Deploy Frontend

ไฟล์ `ansible/frontend/deploy_frontend.yml` ใช้ deploy frontend

Flow ของ playbook นี้คือ

1. deploy frontend จำนวน 2 replicas
2. ใช้ image `thamonwanfirst/monkeypop-frontend`
3. สร้าง Frontend Service แบบ NodePort ที่ port `30001`
4. สั่ง rollout restart เพื่อให้ frontend ใช้ image ล่าสุด

---

## 7. Kubernetes รันระบบจริง

หลังจาก deploy เสร็จ ระบบจะรันอยู่ใน Kubernetes namespace `monkeypop`

ไฟล์ manifest ที่เกี่ยวข้องอยู่ในโฟลเดอร์ `k8s/`

```text
k8s/
├── namespace.yaml
├── configmap.yaml
├── secret.yaml
├── pvc.yaml
├── deployment.yaml
├── service.yaml
├── monitoring.yaml
├── monitoring-deployment.yaml
└── kube-state-metrics.yaml
```

### 7.1 Resource พื้นฐาน

ไฟล์ `k8s/namespace.yaml` ใช้สร้าง namespace `monkeypop`

ไฟล์ `k8s/configmap.yaml` ใช้สร้าง ConfigMap ชื่อ `backend-config` เพื่อเก็บ `REDIS_URL`

ไฟล์ `k8s/secret.yaml` ใช้สร้าง Secret ชื่อ `backend-secret` เพื่อเก็บ `API_KEY`

ไฟล์ `k8s/pvc.yaml` ใช้สร้าง PersistentVolumeClaim ชื่อ `redis-pvc` สำหรับให้ Redis เก็บข้อมูลถาวร

### 7.2 Deployment ของแอป

ไฟล์ `k8s/deployment.yaml` รวม Deployment ของ 3 ส่วนหลัก

- `redis` ใช้ image `redis:alpine`
- `backend` ใช้ image `thamonwanfirst/monkeypop-backend:latest`
- `frontend` ใช้ image `thamonwanfirst/monkeypop-frontend:latest`

backend และ frontend ถูกตั้งให้มี 2 replicas เพื่อให้มี pod มากกว่า 1 ตัว

### 7.3 Service สำหรับเข้าถึงระบบ

ไฟล์ `k8s/service.yaml` รวม Service ของระบบ

- Redis Service เปิด port `6379` ให้ backend ติดต่อ Redis ภายใน cluster
- Backend Service เปิด NodePort `30002`
- Frontend Service เปิด NodePort `30001`

ผู้เล่นจะเข้าเกมผ่าน frontend ที่ port `30001` ส่วน frontend จะเรียก backend ที่ port `30002`

---

## 8. Flow ตอนผู้เล่นใช้งานเกม

เมื่อระบบรันบน Kubernetes แล้ว flow ตอนใช้งานจริงจะเป็นแบบนี้

1. ผู้เล่นเปิดหน้าเว็บ frontend ผ่าน NodePort `30001`
2. Kubernetes ส่ง request ไปยัง pod ของ frontend
3. nginx ใน frontend container serve ไฟล์ `index.html`
4. ผู้เล่นกรอกชื่อและกดเริ่มเกม
5. JavaScript ใน `index.html` เริ่มจับเวลา 30 วินาที
6. ผู้เล่นกดรูปลิงเพื่อเพิ่มคะแนน
7. เมื่อหมดเวลา frontend ส่ง `POST /api/score` ไป backend port `30002`
8. backend ตรวจสอบ `x-api-key`
9. backend บันทึกคะแนนลง Redis ด้วย sorted set
10. frontend เรียก `GET /api/leaderboard`
11. backend ดึง Top 5 จาก Redis แล้วส่งกลับไปแสดงบนหน้าเว็บ

Flow การเล่นเกมแบบย่อ

```text
Browser
  -> Frontend Service :30001
  -> Frontend Pod
  -> Backend Service :30002
  -> Backend Pod
  -> Redis Service :6379
  -> Redis Pod
```

---

## 9. Backend ส่ง Metrics ให้ Prometheus

นอกจากรับคะแนนแล้ว backend ยังสร้าง metrics สำหรับ monitoring ด้วย

ใน `backend/server.js` มีการใช้ `prom-client` เพื่อสร้าง metric ชื่อ

```text
monkey_pops_total
```

metric นี้ใช้เก็บจำนวนการกดทั้งหมด โดยแยกตาม username

backend เปิด endpoint

```text
/metrics
```

Prometheus จะเรียก endpoint นี้เป็นระยะ ๆ เพื่อเก็บ metrics

---

## 10. Prometheus เก็บ Metrics

Prometheus มีทั้ง config สำหรับ local และ config สำหรับ Kubernetes

ไฟล์ที่เกี่ยวข้องคือ

```text
prometheus/
├── prometheus.yml
├── alert_rules.yml
└── rbac.yaml
```

และใน Kubernetes มีไฟล์

```text
k8s/monitoring.yaml
k8s/monitoring-deployment.yaml
k8s/kube-state-metrics.yaml
```

### 10.1 `prometheus/prometheus.yml`

ไฟล์นี้กำหนดว่า Prometheus ต้องไปดึง metrics จากที่ไหน เช่น

- Prometheus เอง
- backend
- node-exporter
- kube-state-metrics

### 10.2 `prometheus/alert_rules.yml`

ไฟล์นี้กำหนด alert rule เช่น

- `BackendDown` แจ้งเตือนเมื่อ backend ล่ม
- `HighClickRate` แจ้งเตือนเมื่อจำนวนการกดสูงผิดปกติ
- `RedisDown` แจ้งเตือนเมื่อ Redis ใช้งานไม่ได้

### 10.3 `prometheus/rbac.yaml`

ไฟล์นี้ให้สิทธิ์ Prometheus อ่าน resource ใน Kubernetes เช่น pod, service และ endpoint

ประกอบด้วย

- ServiceAccount
- ClusterRole
- ClusterRoleBinding

### 10.4 Monitoring Manifest ใน `k8s/`

ไฟล์ `k8s/monitoring.yaml` ใช้สร้าง ConfigMap สำหรับ Prometheus และ Grafana

ไฟล์ `k8s/monitoring-deployment.yaml` ใช้ deploy Prometheus และ Grafana

- Prometheus เปิด NodePort `30090`
- Grafana เปิด NodePort `30000`

ไฟล์ `k8s/kube-state-metrics.yaml` ใช้ deploy kube-state-metrics เพื่อให้ Prometheus เห็นสถานะของ Kubernetes เช่น pod running, pending และ restart count

---

## 11. Grafana แสดงผล Dashboard

Grafana ใช้ข้อมูลจาก Prometheus เพื่อแสดง dashboard

โฟลเดอร์ที่เกี่ยวข้องคือ

```text
grafana/
├── dashboards/
│   └── monkeypop-dashboard.json
└── provisioning/
    ├── datasources/
    │   └── datasources.yaml
    └── dashboards/
        └── dashboards.yaml
```

### 11.1 Datasource

ไฟล์ `grafana/provisioning/datasources/datasources.yaml` กำหนดให้ Grafana ใช้ Prometheus เป็น datasource

URL ที่ใช้คือ

```text
http://prometheus:9090
```

### 11.2 Dashboard Provider

ไฟล์ `grafana/provisioning/dashboards/dashboards.yaml` บอก Grafana ให้โหลด dashboard จาก path

```text
/var/lib/grafana/dashboards
```

### 11.3 Dashboard JSON

ไฟล์ `grafana/dashboards/monkeypop-dashboard.json` คือ dashboard ของโปรเจกต์

panel หลัก ได้แก่

- `Total Monkey Pops` แสดงจำนวนการกดทั้งหมด
- `Pod Restarts` แสดงจำนวนครั้งที่ pod restart
- `Pods Status` แสดงสถานะของ pod
- `Memory by Pod` แสดง memory usage ของ backend pod

Flow ของ monitoring คือ

```text
Backend / Kubernetes
  -> Prometheus
  -> Grafana
  -> Dashboard
```

---

## 12. ไฟล์เอกสารและไฟล์ช่วยจัดการโปรเจกต์

### `README.md`

เป็นเอกสารหลักของโปรเจกต์ ใช้อธิบายภาพรวม วิธีรัน วิธี deploy และรายละเอียดของระบบ

### `readawrite.md`

เป็นเอกสารฉบับนี้ ใช้อธิบายโปรเจกต์แบบไล่ตาม flow การทำงาน

### `.gitignore`

ใช้บอก Git ว่าไม่ต้อง track ไฟล์หรือโฟลเดอร์บางอย่าง เช่น

- `node_modules/`
- `dist/`
- `*.log`
- `.env`
- `grafana-storage/`
- `jenkins-data/`

---

## 13. สรุป Flow ทั้งหมดแบบสั้น

1. Developer เขียนโค้ดใน `frontend/` และ `backend/`
2. Dockerfile แปลง frontend/backend เป็น Docker image
3. Jenkins pipeline เริ่มทำงานเมื่อมีการ push code
4. Jenkins build และ push image ไป Docker Hub
5. Terraform สร้าง namespace, ConfigMap, Secret และ Redis
6. Ansible deploy backend และ frontend เข้า Kubernetes
7. Kubernetes รัน frontend, backend และ Redis เป็น pod
8. ผู้เล่นเข้าเกมผ่าน frontend port `30001`
9. frontend ส่งคะแนนไป backend port `30002`
10. backend บันทึกคะแนนลง Redis
11. backend เปิด `/metrics` ให้ Prometheus ดึงข้อมูล
12. Prometheus เก็บ metrics จาก backend และ Kubernetes
13. Grafana แสดง dashboard จากข้อมูลของ Prometheus

---

## 14. สรุปหน้าที่ของแต่ละโฟลเดอร์

| โฟลเดอร์ | อยู่ใน Flow ช่วงไหน | หน้าที่ |
|---|---|---|
| `frontend/` | Runtime | หน้าเว็บเกมที่ผู้เล่นใช้งาน |
| `backend/` | Runtime | API รับคะแนน ดึง leaderboard และส่ง metrics |
| `Terraform/` | ก่อน deploy | สร้าง resource พื้นฐาน เช่น namespace, ConfigMap, Secret และ Redis |
| `ansible/` | ตอน deploy | deploy backend และ frontend เข้า Kubernetes |
| `jenkins/` | CI/CD | build, test, push image และสั่ง deploy |
| `k8s/` | Kubernetes runtime | manifest สำหรับ resource บน Kubernetes |
| `prometheus/` | Monitoring | config การเก็บ metrics และ alert |
| `grafana/` | Monitoring | datasource และ dashboard สำหรับแสดงผล |

