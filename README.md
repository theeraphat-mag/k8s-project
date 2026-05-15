# 🚀 Monkey Pop Pop — ENG23 3074

> **เกมกดลิงยอดฮิตที่มีระบบ CI/CD อัตโนมัติและ Monitoring แบบ Full-Stack**  
> พัฒนาด้วย Node.js และ Redis, ทำ Containerization ด้วย Docker, บริหารจัดการ Infrastructure ด้วย Terraform (K8s Provider) และ Ansible, Deploy บน Kubernetes ผ่าน Jenkins CI/CD พร้อมระบบ Monitoring ด้วย Prometheus และ Grafana

---

## 👥 สมาชิกในกลุ่ม

| รหัสนักศึกษา | ชื่อ-นามสกุล | ความรับผิดชอบ |
|-------------|-------------|---------------|
| B66515574 | นายธีระพัฒน์ แสวงดี | Git, App Development |
| B6619404 | นายธีรภัทร จันทสุรีย์ | Jenkins, Docker |
| B6644468 | นางสาวอัฐภิญญา จันทร์หนองหว้า | Terraform, Ansible |
| B6615406 | นางสาวธมนวรรณ เกริ่นกระโทก | Kubernetes, Monitoring |

---

## 📌 ภาพรวมโปรเจค

### แอปพลิเคชัน
- **ชื่อ:** Monkey Pop Pop
- **ประเภท:** Web Application (Frontend + Backend + Database)
- **ภาษา / Framework:** Node.js Express (Backend), HTML/CSS/JS (Frontend), Redis (Database)
- **คำอธิบาย:** เกมแนวคลิกเก็บคะแนนที่เน้นการออกแบบระบบ Cloud-Native โดยมีการใช้ Redis เพื่อเก็บ Leaderboard และมีระบบ Monitoring ติดตามผลแบบ Real-time

### Architecture Diagram
```
Developer
    │
    ▼  git push
 GitHub ──── webhook ────▶ Jenkins CI/CD
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
                 Build        Test      Docker Build
                                            │
                                            ▼
                                       Docker Hub
                                            │
                                    ┌───────┴───────┐
                                    ▼               ▼
                                Terraform        Ansible
                                    │               │
                                    └───────┬───────┘
                                            ▼
                                   Kubernetes Cluster
                                   ┌────────────────┐
                                   │  Pod 1  Pod 2  │
                                   │  [App]  [App]  │
                                   │                │
                                   │  Service (NodePort :30001)  │
                                   └────────────────┘
                                            │
                              ┌─────────────┴──────────────┐
                              ▼                             ▼
                          Prometheus  ──────────────▶  Grafana
                        (scrape /metrics)            (dashboard)
```

---

## 📁 โครงสร้าง Repository

```
k8s-project/
├── backend/                # API Service (Node.js)
├── frontend/               # Web Interface (HTML/CSS/JS)
├── ansible/                # Playbooks สำหรับ Automated Deployment
├── grafana/                # การตั้งค่า Grafana และ Dashboard
├── jenkins/
│   └── build/              # Jenkinsfiles สำหรับ CI/CD (Frontend/Backend)
├── k8s/                    # Kubernetes Manifests (PVC, Service, Deployment)
├── prometheus/             # การตั้งค่า Prometheus และ Alerting
├── Terraform/              # Infrastructure as Code (Namespace, ConfigMap, Secret)
└── README.md
```

---

## ⚙️ สิ่งที่ต้องติดตั้งก่อน (Prerequisites)

| Tool | Version | หน้าที่ |
|------|---------|---------|
| Git | ≥ 2.x | จัดการ source code |
| Docker | ≥ 24.x | สร้างและรัน container |
| Jenkins | ≥ 2.4xx | ระบบ CI/CD automation |
| Terraform | ≥ 1.x | Provision infrastructure |
| Ansible | ≥ 2.15 | Configure environment |
| kubectl | ≥ 1.28 | สั่งงาน Kubernetes cluster |
| Minikube / K3s | latest | Kubernetes แบบ local |
| Prometheus | ≥ 2.x | เก็บ metrics |
| Grafana | ≥ 10.x | แสดง dashboard |

---

## 🏃 วิธีรันโปรเจค (Quick Start)

### 1. Clone Repository
```bash
git clone https://github.com/[username]/k8s-project.git
cd k8s-project
```

### 2. รันด้วย Docker Compose (Local Testing)
```bash
docker-compose up --build
```

### 3. การใช้งานผ่าน Kubernetes (Manual)
```bash
# เตรียม Infra ด้วย Terraform
cd Terraform
terraform init && terraform apply -auto-approve

# Deploy แอปด้วย Ansible
cd ../ansible
ansible-playbook -i backend/hosts.ini backend/deploy_backend.yml
ansible-playbook -i frontend/hosts.ini frontend/deploy_frontend.yml
```

---

## 🔄 CI/CD Pipeline (Jenkins)

ระบบแบ่ง Pipeline เป็น 2 ส่วนหลัก:
1. **Backend Pipeline:** จัดการ Build Image และเตรียม Infrastructure (Terraform)
2. **Frontend Pipeline:** จัดการ Build Image และ Deploy แอปพลิเคชัน (Ansible)

| Stage | คำอธิบาย |
|-------|----------|
| **Checkout** | ดึงโค้ดล่าสุดจาก GitHub |
| **Docker Build** | สร้าง Docker image จาก Dockerfile ใน backend/frontend |
| **Push to Hub** | อัปโหลด image ขึ้น Docker Hub |
| **Infrastructure** | (เฉพาะ Backend) รัน Terraform เพื่อสร้าง Namespace และ Resources |
| **Deploy** | รัน Ansible เพื่อ Deploy และ Rollout Restart Pods ใน K8s |

---

## 🏗️ Infrastructure as Code

### Terraform — Provision Infrastructure
ใช้ Terraform (Kubernetes Provider) ในการจัดการ:
- **Namespace:** `monkeypop`
- **ConfigMap:** เก็บการตั้งค่า environment
- **Secret:** เก็บข้อมูลสำคัญ เช่น API Key

### Ansible — Configure Environment
ใช้ Ansible ในการ:
- จัดการการ Deploy Kubernetes manifests
- ทำ **Rollout Restart** เพื่อให้อัปเดต image ใหม่โดยไม่มี downtime

---

## ☸️ Kubernetes Deployment

### ตรวจสอบสถานะ
```bash
kubectl get all -n monkeypop
```

### การเข้าถึงแอปพลิเคชัน (Port Forward)
```bash
# Frontend
kubectl port-forward svc/frontend 30001:80 -n monkeypop
# Backend
kubectl port-forward svc/backend 30002:3001 -n monkeypop
```
kubectl get svc -n monkeypop

---

## 📊 Monitoring

### ระบบที่ใช้
- **Prometheus:** เก็บ metrics จาก `/metrics` endpoint ของ backend และข้อมูลระบบจาก K8s
- **Grafana:** แสดงผล Dashboard (Port 30000)
- **kube-state-metrics:** ตัวช่วยดึงข้อมูลสถานะของทรัพยากรต่างๆ ใน Kubernetes

### Panels ใน Dashboard
  - **Total Monkey Pops:** จำนวนการกดทั้งหมด (ดึงจากแอป)
  - **Pod Restarts:** ตรวจสอบความเสถียรของ Pod (ดึงจาก kube-state-metrics)
  - **Pods Status:** ตรวจสอบสถานะ Pod เช่น Running/Pending (ดึงจาก kube-state-metrics)
  - **Memory by Pod:** การใช้หน่วยความจำ (RSS) ของแต่ละ Pod (ดึงจากแอป)

### การเข้าใช้งาน
```bash
# เข้าผ่าน NodePort (หากใช้ Minikube ให้ใช้ minikube ip)
# Grafana: http://<NODE_IP>:30000
# Prometheus: http://<NODE_IP>:30090
```

---

## 🌿 Branching Strategy

```
main        ──── โค้ดที่พร้อม production
dev         ──── รวมโค้ดก่อน merge ขึ้น main
feature/*   ──── พัฒนา feature แยก (เช่น feature/monitoring)
```

---

## 🧪 API Endpoints

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `GET` | `/metrics` | Prometheus metrics endpoint |
| `GET` | `/api/leaderboard` | ดึงข้อมูล Top 5 Leaderboard |
| `POST` | `/api/score` | ส่งคะแนนใหม่ (ต้องใช้ x-api-key ใน Header) |

---

## 🐛 ปัญหาที่พบบ่อย (Troubleshooting)

**Pods ค้างอยู่ที่ Pending**
- ตรวจสอบ PVC ว่าถูกสร้างและ Bound หรือยัง: `kubectl get pvc -n monkeypop`
- ตรวจสอบทรัพยากรใน Cluster

**Prometheus ไม่เห็น Metrics**
- ตรวจสอบว่า Service ของ Backend เปิดพอร์ต 3001 ถูกต้อง
- เช็ค log ของ backend pod: `kubectl logs [pod-name] -n monkeypop`

---

## 📚 เอกสารอ้างอิง

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Ansible K8s Module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html)
- [Prometheus Node.js Client](https://github.com/siimon/prom-client)

---

## 📄 ข้อมูลการส่งงาน

- **วิชา:** ENG23 3074 — Serverless and Cloud Architectures
- **อาจารย์ผู้สอน:** ดร. นันทวุฒิ คะอังกุ
- **ภาควิชาวิศวกรรมคอมพิวเตอร์ มหาวิทยาลัยเทคโนโลยีสุรนารี**
