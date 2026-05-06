# 🚀 Monkey Pop Pop — ENG23 3074

> **เกมกดลิงยอดฮิตที่มีระบบ Live Ranking แบบ Real-time**  
> พัฒนาด้วย Node.js และ Redis, ทำ Containerization ด้วย Docker, บริหารจัดการ Infrastructure ด้วย Terraform และ Ansible, Deploy บน Kubernetes ผ่าน Jenkins CI/CD พร้อมระบบ Monitoring เต็มรูปแบบ

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
- **ประเภท:** Web Application (Real-time Clicker Game)
- **ภาษา / Framework:** Node.js (Express), Vanilla JS, Redis (Leaderboard)
- **คำอธิบาย:** เกมแข่งขันการคลิกเพื่อเก็บคะแนนและแสดงอันดับ Top 5 แบบ Real-time รองรับการเก็บ Metrics สำหรับ Monitoring และมีระบบ Security ด้วย API Key

### Architecture Diagram
```
Developer
    │
    ▼  git push
 GitHub ──── webhook ────▶ Jenkins CI/CD (Build & Deploy)
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
                 Build        Test      Docker Build
                                            │
                                            ▼
                                       Docker Hub (thamonwanfirst/*)
                                            │
                                    ┌───────┴───────┐
                                    ▼               ▼
                                Terraform        Ansible
                             (Docker Env)     (K8s Deploy)
                                    │               │
                                    └───────┬───────┘
                                            ▼
                                   Kubernetes Cluster (Namespace: monkeypop)
                                   ┌─────────────────────────┐
                                   │  Frontend Pods (x2)     │
                                   │  Backend Pods (x2)      │
                                   │  Redis Pod (x1)         │
                                   └─────────────────────────┘
                                            │
                              ┌─────────────┴──────────────┐
                              ▼                             ▼
                          Prometheus  ──────────────▶  Grafana
                        (NodePort: 30090)            (NodePort: 30000)
```

---

## 📁 โครงสร้าง Repository

```
k8s-project/
├── backend/                # โค้ด Backend API (Node.js)
├── frontend/               # โค้ด Frontend Web (HTML/JS/Assets)
├── jenkins/                # Jenkins Pipeline แยกตาม stage
│   ├── build/              # Pipeline สำหรับ Build & Push Image
│   └── deploy/             # Pipeline สำหรับ Deploy ผ่าน Ansible
├── Terraform/              # Infrastructure as Code สำหรับ Docker
├── ansible/                # Configuration Management สำหรับ K8s Deploy
├── k8s/                    # Kubernetes Manifests (App & Monitoring)
├── prometheus/             # การตั้งค่า Prometheus และ RBAC
├── grafana/                # การตั้งค่า Grafana และ Dashboards
├── Docker-compose.yml      # สำหรับรันระบบทั้งหมดบน Local Docker
└── README.md
```

---

## 🏃 วิธีรันโปรเจค (Quick Start)

### 1. รันด้วย Docker Compose (Local Test)
```bash
docker-compose up -d
# เข้าเกมที่: http://localhost
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000
```

### 2. รันบน Kubernetes (Manual Deploy)
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
```

---

## 🔄 CI/CD Pipeline (Jenkins)

โปรเจคนี้แบ่ง Pipeline ออกเป็น 2 ส่วนหลัก:
1. **Build Pipeline:** อยู่ใน `jenkins/build/` ทำหน้าที่ดึงโค้ด, Build Image และ Push ไปยัง Docker Hub (`thamonwanfirst/monkeypop-*`)
2. **Deploy Pipeline:** อยู่ใน `jenkins/deploy/` ทำหน้าที่เรียกใช้ Ansible เพื่อ Deploy Manifests ลงใน Kubernetes Cluster

---

## 🏗️ Infrastructure as Code

### Terraform (Docker Management)
จัดการ Docker Resources สำหรับสภาพแวดล้อมการพัฒนา:
- **Networks:** `monkeypop-network`
- **Containers:** Redis, Backend, Frontend

### Ansible (Kubernetes Orchestration)
ทำหน้าที่ Deploy แอปพลิเคชันลง Kubernetes อย่างแม่นยำ:
- จัดการ Namespace `monkeypop`
- จัดการ Deployment และ Service (NodePort)
- กำหนดค่า Resource และพอร์ตให้ตรงกันทั้งระบบ

---

## ☸️ Kubernetes Deployment

| Service | Type | Port | NodePort |
|---------|------|------|----------|
| Frontend | NodePort | 80 | 30001 |
| Backend | NodePort | 3001 | 30002 |
| Redis | ClusterIP | 6379 | - |
| Prometheus | NodePort | 9090 | 30090 |
| Grafana | NodePort | 3000 | 30000 |

---

## 📊 Monitoring

ระบบ Monitoring ถูกตั้งค่าให้ทำงานบน Kubernetes โดยอัตโนมัติ:
- **Prometheus:** ทำ Service Discovery ค้นหา Pod ของ Backend อัตโนมัติผ่าน Labels
- **Grafana:** มีการทำ Provisioning ข้อมูลและ Dashboard "MonkeyPop Monitoring" ไว้ล่วงหน้า
- **Metrics:** ติดตามจำนวนการคลิกรวม (Total Pops), อัตราการคลิก (Click Rate), และ Memory Usage

---

## 🧪 API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `GET` | `/api/leaderboard` | ดึงข้อมูล Top 5 Ranking | No |
| `POST` | `/api/score` | บันทึกคะแนนใหม่ | **Yes (x-api-key)** |
| `GET` | `/metrics` | Prometheus Metrics | No |

---

## 📄 ข้อมูลการส่งงาน

- วิชา: **ENG23 3074 — Serverless and Cloud Architectures**
- อาจารย์ผู้สอน: **ดร. นันทวุฒิ เกาะกุ้ง (AFHEA)**
- ภาควิชาวิศวกรรมคอมพิวเตอร์ มหาวิทยาลัยเทคโนโลยีสุรนารี
