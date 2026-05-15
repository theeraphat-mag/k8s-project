# อธิบายโครงสร้างโปรเจกต์ Monkey Pop Pop

โปรเจกต์นี้คือเว็บเกม **Monkey Pop Pop** ที่มีทั้งหน้าเว็บเกม, backend API, ฐานข้อมูล Redis, ระบบ deploy ด้วย Docker/Kubernetes, pipeline อัตโนมัติด้วย Jenkins, Infrastructure as Code ด้วย Terraform/Ansible และระบบ Monitoring ด้วย Prometheus/Grafana

ภาพรวมการทำงานคือ ผู้เล่นเปิดหน้าเว็บจาก `frontend` แล้วกดเล่นเกม เมื่อจบเกม frontend จะส่งคะแนนไปที่ `backend` จากนั้น backend จะเก็บคะแนนใน `Redis` และเปิด `/metrics` ให้ `Prometheus` ดึงข้อมูลไปแสดงผลบน `Grafana`

---

## โครงสร้างหลักของโปรเจกต์

```text
k8s-project/
├── ansible/
├── backend/
├── frontend/
├── grafana/
├── jenkins/
├── k8s/
├── prometheus/
├── Terraform/
├── .gitignore
├── Docker-compose.yml
├── Dockerfile.jenkins
├── README.md
└── readawrite.md
```

---

## ไฟล์ในโฟลเดอร์หลัก

### `README.md`

เป็นเอกสารหลักของโปรเจกต์ ใช้อธิบายภาพรวมโปรเจกต์ วิธีรัน ระบบ CI/CD, Kubernetes, Terraform, Ansible, Prometheus และ Grafana

### `readawrite.md`

เป็นไฟล์เอกสารที่ใช้สรุปและอธิบายหน้าที่ของแต่ละโฟลเดอร์และแต่ละไฟล์ในโปรเจกต์

### `.gitignore`

ใช้กำหนดไฟล์หรือโฟลเดอร์ที่ไม่ต้องการให้ Git track เช่น

- `node_modules/`
- `dist/`
- `*.log`
- `.env`
- `grafana-storage/`
- `jenkins-data/`

### `Docker-compose.yml`

ใช้รันระบบหลาย container พร้อมกันแบบ local โดยรวม service หลัก เช่น

- `frontend`
- `backend`
- `redis`
- `prometheus`
- `grafana`
- `jenkins`
- `node-exporter`
- `k8s-proxy`

ไฟล์นี้เหมาะสำหรับใช้ทดสอบระบบทั้งหมดบนเครื่อง local ก่อน deploy จริง

### `Dockerfile.jenkins`

ใช้สร้าง Jenkins image สำหรับโปรเจกต์นี้โดยเฉพาะ ภายใน Jenkins image จะติดตั้งเครื่องมือที่จำเป็น เช่น

- Ansible
- Docker CLI
- Terraform
- kubectl
- Node.js

เพราะ Jenkins ต้องใช้เครื่องมือเหล่านี้ในการ build image, push image, สร้าง infrastructure และ deploy ไป Kubernetes

---

## โฟลเดอร์ `backend/`

โฟลเดอร์นี้คือส่วน backend API ของเกม เขียนด้วย Node.js และ Express ทำหน้าที่รับคะแนน เก็บคะแนนใน Redis และเปิด metrics ให้ Prometheus

```text
backend/
├── Dockerfile
├── package.json
└── server.js
```

### `backend/server.js`

เป็นไฟล์หลักของ backend ทำหน้าที่เปิด Express server ที่ port `3001`

หน้าที่สำคัญ:

- เชื่อมต่อ Redis ผ่าน `REDIS_URL`
- เปิด API สำหรับส่งคะแนน
- เปิด API สำหรับดึง leaderboard
- เปิด endpoint `/metrics` ให้ Prometheus ดึงข้อมูล
- ใช้ `prom-client` เก็บ metrics ชื่อ `monkey_pops_total`
- ตรวจสอบ API key จาก header `x-api-key`

API ที่มีในไฟล์นี้:

| Method | Endpoint | หน้าที่ |
|---|---|---|
| `GET` | `/metrics` | ให้ Prometheus ดึง metrics |
| `GET` | `/api/leaderboard` | ดึง Top 5 leaderboard จาก Redis |
| `POST` | `/api/score` | รับคะแนนผู้เล่นแล้วบันทึกลง Redis |

### `backend/package.json`

เป็นไฟล์กำหนดข้อมูลของ Node.js project เช่น ชื่อโปรเจกต์ script สำหรับรัน และ dependencies

dependencies ที่ใช้:

- `express` สำหรับสร้าง API server
- `redis` สำหรับเชื่อมต่อฐานข้อมูล Redis
- `cors` สำหรับอนุญาตให้ frontend เรียก backend ได้
- `prom-client` สำหรับสร้าง metrics ให้ Prometheus
- `uuid` สำหรับสร้าง unique id ถ้าต้องใช้ในอนาคต

คำสั่งหลัก:

```bash
npm start
```

### `backend/Dockerfile`

ใช้ build backend เป็น Docker image

ขั้นตอนหลัก:

1. ใช้ base image `node:18-alpine`
2. ตั้ง working directory เป็น `/app`
3. copy `package.json`
4. ติดตั้ง dependencies ด้วย `npm install`
5. copy source code ทั้งหมด
6. expose port `3001`
7. รัน backend ด้วย `npm start`

---

## โฟลเดอร์ `frontend/`

โฟลเดอร์นี้คือหน้าเว็บเกม Monkey Pop Pop เป็น static website ที่ใช้ HTML, CSS และ JavaScript

```text
frontend/
├── Dockerfile
├── index.html
├── background.png
├── monkey1.png
├── monkey2.png
└── chieuk-thinking-289286.mp3
```

### `frontend/index.html`

เป็นไฟล์หลักของหน้าเกม รวมทั้ง HTML, CSS และ JavaScript ไว้ในไฟล์เดียว

หน้าที่สำคัญ:

- แสดงหน้า login ให้ผู้เล่นกรอกชื่อ
- แสดงตัวจับเวลา 30 วินาที
- แสดงคะแนนขณะเล่น
- แสดง Top 5 leaderboard
- เปลี่ยนรูปลิงเมื่อผู้เล่นกด
- เล่นเสียงตอนกด
- ส่งคะแนนไป backend หลังจบเกม
- ดึง leaderboard จาก backend มาแสดง

ในไฟล์นี้มีการกำหนด `API_URL` ให้เลือก backend ตาม environment:

- ถ้ารันผ่าน Kubernetes NodePort จะเรียก backend ที่ port `30002`
- ถ้ารัน local จะเรียก `http://localhost:3001`

### `frontend/Dockerfile`

ใช้ build frontend เป็น Docker image โดยใช้ `nginx:alpine`

หน้าที่:

- copy ไฟล์ทั้งหมดใน `frontend/` ไปไว้ที่ `/usr/share/nginx/html/`
- expose port `80`
- รัน nginx เพื่อ serve หน้าเว็บ

### `frontend/background.png`

เป็นรูปพื้นหลังของเกม

### `frontend/monkey1.png`

เป็นรูปลิงสถานะปกติ ก่อนถูกกด

### `frontend/monkey2.png`

เป็นรูปลิงสถานะตอนถูกกด ใช้สลับภาพเพื่อให้เกมมี animation ง่าย ๆ

### `frontend/chieuk-thinking-289286.mp3`

เป็นไฟล์เสียงที่เล่นตอนผู้เล่นกดลิง

---

## โฟลเดอร์ `ansible/`

โฟลเดอร์นี้ใช้เก็บ Ansible playbook สำหรับ deploy frontend และ backend เข้า Kubernetes

```text
ansible/
├── backend/
│   ├── deploy_backend.yml
│   └── hosts.ini
└── frontend/
    ├── deploy_frontend.yml
    └── hosts.ini
```

### `ansible/backend/hosts.ini`

กำหนด target host สำหรับ Ansible

```ini
server ansible_host=localhost ansible_connection=local
```

หมายความว่า Ansible จะรันคำสั่งบนเครื่อง local หรือใน Jenkins container ที่กำลังทำงานอยู่

### `ansible/backend/deploy_backend.yml`

เป็น playbook สำหรับ deploy backend และ Redis เข้า Kubernetes

หน้าที่หลัก:

- สร้าง namespace `monkeypop`
- สร้าง Redis PVC สำหรับเก็บข้อมูลถาวร
- deploy Redis
- สร้าง Redis Service
- deploy backend จำนวน 2 replicas
- ดึงค่า `REDIS_URL` จาก ConfigMap
- ดึงค่า `API_KEY` จาก Secret
- สร้าง Backend Service แบบ NodePort ที่ port `30002`
- สั่ง rollout restart เพื่อให้ backend ใช้ image ล่าสุด

### `ansible/frontend/hosts.ini`

กำหนด target host สำหรับ deploy frontend แบบ local เช่นเดียวกับ backend

### `ansible/frontend/deploy_frontend.yml`

เป็น playbook สำหรับ deploy frontend เข้า Kubernetes

หน้าที่หลัก:

- สร้าง namespace `monkeypop`
- deploy frontend จำนวน 2 replicas
- ใช้ image `thamonwanfirst/monkeypop-frontend`
- สร้าง Frontend Service แบบ NodePort ที่ port `30001`
- สั่ง rollout restart เพื่อให้ frontend ใช้ image ล่าสุด

---

## โฟลเดอร์ `jenkins/`

โฟลเดอร์นี้เก็บ Jenkins Pipeline สำหรับทำ CI/CD

```text
jenkins/
└── build/
    ├── Jenkinsfile_backend
    └── Jenkinsfile_frountend
```

### `jenkins/build/Jenkinsfile_backend`

เป็น pipeline สำหรับ backend

ลำดับการทำงาน:

1. Checkout code จาก GitHub
2. เข้าโฟลเดอร์ `backend` แล้วรัน `npm install`
3. รันทดสอบแบบจำลอง
4. build Docker image ของ backend
5. push image ไป Docker Hub
6. รัน Terraform เพื่อสร้างหรือจัดการ namespace, ConfigMap และ Secret
7. รัน Ansible เพื่อ deploy backend และ Redis
8. deploy monitoring stack เช่น Prometheus, Grafana และ kube-state-metrics
9. ลบ Docker image ในเครื่อง Jenkins หลังจบ pipeline

### `jenkins/build/Jenkinsfile_frountend`

เป็น pipeline สำหรับ frontend

ลำดับการทำงาน:

1. Checkout code จาก GitHub
2. ตรวจสอบไฟล์ frontend เช่น `index.html`
3. build Docker image ของ frontend
4. push image ไป Docker Hub
5. รัน Ansible เพื่อ deploy frontend เข้า Kubernetes
6. ลบ Docker image ในเครื่อง Jenkins หลังจบ pipeline

หมายเหตุ: ชื่อไฟล์สะกดเป็น `frountend` ซึ่งน่าจะตั้งใจหมายถึง `frontend`

---

## โฟลเดอร์ `k8s/`

โฟลเดอร์นี้เก็บ Kubernetes manifest สำหรับสร้าง resource ต่าง ๆ ใน cluster

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

### `k8s/namespace.yaml`

สร้าง namespace ชื่อ `monkeypop`

namespace ใช้แยก resource ของโปรเจกต์นี้ออกจากระบบอื่นใน Kubernetes

### `k8s/configmap.yaml`

สร้าง ConfigMap ชื่อ `backend-config`

เก็บค่า:

```yaml
REDIS_URL: "redis://redis:6379"
```

backend ใช้ค่านี้เพื่อเชื่อมต่อ Redis

### `k8s/secret.yaml`

สร้าง Secret ชื่อ `backend-secret`

เก็บค่า API key:

```yaml
API_KEY: bW9ua2V5LXNlY3JldC1rZXk=
```

ค่านี้คือ base64 ของ `monkey-secret-key`

### `k8s/pvc.yaml`

สร้าง PersistentVolumeClaim ชื่อ `redis-pvc`

ใช้จอง storage ขนาด `1Gi` ให้ Redis เพื่อให้ข้อมูล leaderboard ไม่หายง่ายเมื่อ container restart

### `k8s/deployment.yaml`

รวม Deployment หลักของระบบ ได้แก่

- `redis`
- `backend`
- `frontend`

รายละเอียด:

- Redis มี 1 replica
- Backend มี 2 replicas และใช้ image `thamonwanfirst/monkeypop-backend:latest`
- Frontend มี 2 replicas และใช้ image `thamonwanfirst/monkeypop-frontend:latest`

### `k8s/service.yaml`

รวม Service สำหรับให้แต่ละ component ติดต่อกัน

- `redis` ใช้ ClusterIP ภายใน cluster port `6379`
- `backend` ใช้ NodePort port `30002`
- `frontend` ใช้ NodePort port `30001`

### `k8s/monitoring.yaml`

สร้าง ConfigMap สำหรับระบบ monitoring

ประกอบด้วย:

- Prometheus config
- Grafana datasource
- Grafana dashboard provider
- Grafana dashboard JSON สำหรับ MonkeyPop

### `k8s/monitoring-deployment.yaml`

deploy Prometheus และ Grafana เข้า Kubernetes

ประกอบด้วย:

- Prometheus Deployment
- Prometheus Service NodePort `30090`
- Grafana Deployment
- Grafana Service NodePort `30000`

### `k8s/kube-state-metrics.yaml`

deploy kube-state-metrics เพื่อให้ Prometheus ดึงข้อมูลสถานะของ Kubernetes ได้ เช่น

- pod running หรือ pending
- pod restart count
- deployment status
- service status

ไฟล์นี้มีทั้ง ServiceAccount, ClusterRole, ClusterRoleBinding, Deployment และ Service

---

## โฟลเดอร์ `prometheus/`

โฟลเดอร์นี้เก็บ configuration ของ Prometheus และ alert rules

```text
prometheus/
├── alert_rules.yml
├── prometheus.yml
└── rbac.yaml
```

### `prometheus/prometheus.yml`

เป็น config หลักของ Prometheus

หน้าที่:

- กำหนด scrape interval
- โหลด alert rule จาก `alert_rules.yml`
- scrape metrics จาก Prometheus เอง
- scrape metrics จาก backend
- scrape metrics จาก node-exporter
- scrape metrics จาก kube-state-metrics

### `prometheus/alert_rules.yml`

เป็นไฟล์กำหนด alert rule

alert ที่มี:

- `BackendDown` แจ้งเตือนเมื่อ backend ล่ม
- `HighClickRate` แจ้งเตือนเมื่อจำนวนการกดสูงผิดปกติ
- `RedisDown` แจ้งเตือนเมื่อ Redis เข้าถึงไม่ได้

### `prometheus/rbac.yaml`

สร้างสิทธิ์ให้ Prometheus อ่านข้อมูลใน Kubernetes ได้

ประกอบด้วย:

- ServiceAccount
- ClusterRole
- ClusterRoleBinding

Prometheus ต้องมีสิทธิ์เหล่านี้เพื่อดู pods, services, endpoints และ metrics ต่าง ๆ ใน cluster

---

## โฟลเดอร์ `grafana/`

โฟลเดอร์นี้เก็บการตั้งค่า Grafana และ dashboard

```text
grafana/
├── dashboards/
│   └── monkeypop-dashboard.json
└── provisioning/
    ├── dashboards/
    │   └── dashboards.yaml
    └── datasources/
        └── datasources.yaml
```

### `grafana/provisioning/datasources/datasources.yaml`

ตั้งค่า datasource ให้ Grafana เชื่อมกับ Prometheus

กำหนดให้ Prometheus เป็น datasource หลักที่ URL:

```text
http://prometheus:9090
```

### `grafana/provisioning/dashboards/dashboards.yaml`

บอก Grafana ให้โหลด dashboard จาก path:

```text
/var/lib/grafana/dashboards
```

ทำให้ Grafana สามารถโหลด dashboard อัตโนมัติเมื่อ container เริ่มทำงาน

### `grafana/dashboards/monkeypop-dashboard.json`

เป็นไฟล์ dashboard ของ Grafana สำหรับโปรเจกต์ MonkeyPop

panel หลักใน dashboard:

- `Total Monkey Pops` แสดงจำนวนการกดทั้งหมด
- `Pod Restarts` แสดงจำนวนครั้งที่ pod restart
- `Pods Status` แสดงสถานะ pod เช่น Running หรือ Pending
- `Memory by Pod` แสดง memory usage ของ backend pod

---

## โฟลเดอร์ `Terraform/`

โฟลเดอร์นี้ใช้ Terraform จัดการ resource พื้นฐานใน Kubernetes

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

### `Terraform/main.tf`

เป็นไฟล์หลักของ Terraform

หน้าที่:

- กำหนด Kubernetes provider
- ใช้ kubeconfig ที่ `/var/jenkins_home/.kube/config`
- สร้าง namespace `monkeypop`
- สร้าง ConfigMap `backend-config`
- สร้าง Secret `backend-secret`

### `Terraform/variables.tf`

กำหนดตัวแปรของ Terraform

ตัวแปรหลัก:

- `namespace_name` ค่า default คือ `monkeypop`
- `redis_url` ค่า default คือ `redis://redis:6379`
- `api_key` ค่า default คือ `monkey-secret-key`

### `Terraform/README.md`

เอกสารอธิบายวิธีใช้ Terraform ในโปรเจกต์ เช่น

- `terraform init`
- `terraform plan`
- `terraform apply -auto-approve`
- `terraform destroy`

### `Terraform/Makefile`

รวมคำสั่งลัดสำหรับจัดการ Terraform เช่น

- `make init`
- `make validate`
- `make fmt`
- `make plan`
- `make apply`
- `make destroy`
- `make clean`

### `Terraform/setup.ps1`

script สำหรับติดตั้ง Terraform บน Windows ผ่าน PowerShell

### `Terraform/setup.sh`

script สำหรับติดตั้ง Terraform บน Linux หรือ macOS

### `Terraform/terraform.bat`

ตัวช่วยรัน Terraform บน Windows CMD

ตัวอย่าง:

```bat
terraform.bat init
terraform.bat plan
terraform.bat apply
```

### `Terraform/terraform.sh`

ตัวช่วยรัน Terraform บน Linux หรือ macOS

ตัวอย่าง:

```bash
./terraform.sh init
./terraform.sh plan
./terraform.sh apply
```

---

## สรุปหน้าที่แต่ละโฟลเดอร์แบบสั้น

| โฟลเดอร์ | หน้าที่ |
|---|---|
| `backend/` | API สำหรับรับคะแนน เก็บ leaderboard และส่ง metrics |
| `frontend/` | หน้าเว็บเกม Monkey Pop Pop |
| `ansible/` | playbook สำหรับ deploy frontend/backend เข้า Kubernetes |
| `jenkins/` | pipeline สำหรับ build, push image และ deploy อัตโนมัติ |
| `k8s/` | manifest สำหรับสร้าง resource บน Kubernetes |
| `prometheus/` | config สำหรับเก็บ metrics และ alert |
| `grafana/` | config datasource และ dashboard สำหรับแสดงผล monitoring |
| `Terraform/` | จัดการ namespace, ConfigMap และ Secret ด้วย Infrastructure as Code |

---

## สรุปการไหลของระบบ

1. ผู้เล่นเปิด frontend ที่ port `30001`
2. frontend แสดงหน้าเกมและรับชื่อผู้เล่น
3. ผู้เล่นกดลิงเพื่อสะสมคะแนน
4. เมื่อหมดเวลา frontend ส่งคะแนนไป backend ที่ port `30002`
5. backend ตรวจสอบ API key
6. backend บันทึกคะแนนลง Redis
7. backend เปิด metrics ให้ Prometheus ดึงข้อมูล
8. Prometheus เก็บ metrics ของ backend และ Kubernetes
9. Grafana ดึงข้อมูลจาก Prometheus ไปแสดง dashboard
10. Jenkins ช่วย build และ deploy ระบบทั้งหมดให้อัตโนมัติ
