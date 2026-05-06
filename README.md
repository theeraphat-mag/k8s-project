# 🚀 Monkey Pop Pop — Serverless & Cloud Architecture (ENG23 3074)

> **เกมกดลิงยอดฮิตที่มีระบบ CI/CD และ Monitoring แบบ Full-Stack**  
> พัฒนาด้วย Node.js และ Redis, ทำ Containerization ด้วย Docker, บริหารจัดการ Infrastructure ด้วย Terraform (K8s Provider) และ Ansible, Deploy บน Kubernetes ผ่าน Jenkins CI/CD แบบอัตโนมัติ 100% พร้อมระบบ Monitoring ด้วย Prometheus และ Grafana

---

## 👥 สมาชิกในกลุ่ม

| รหัสนักศึกษา | ชื่อ-นามสกุล | ความรับผิดชอบ |
|-------------|-------------|---------------|
| B66515574 | นายธีระพัฒน์ แสวงดี | Git, App Development |
| B6619404 | นายธีรภัทร จันทสุรีย์ | Jenkins, Docker |
| B6644468 | นางสาวอัฐภิญญา จันทร์หนองหว้า | Terraform, Ansible |
| B6615406 | นางสาวธมนวรรณ เกริ่นกระโทก | Kubernetes, Monitoring |

---

## 📌 ภาพรวมระบบ (Architecture & Flow)

### 🔄 CI/CD Flow:
**Code** (Developer) ➔ **Git** (Push) ➔ **Jenkins** (Webhook/Ngrok) ➔ **Docker** (Build & Push) ➔ **Terraform** (K8s Infrastructure) ➔ **Ansible** (K8s Deploy) ➔ **Kubernetes** ➔ **Monitoring** (Prometheus/Grafana)

### 🏗️ Infrastructure Components:
- **Terraform:** จัดการ "โครงสร้าง" พื้นฐานใน Kubernetes (Namespace, ConfigMap, Secret)
- **Ansible:** จัดการ "การติดตั้ง" แอปพลิเคชัน (Deployment, Service) พร้อมคำสั่ง Rollout Restart อัตโนมัติ
- **Kubernetes:** รันแอปพลิเคชันแบบ High Availability (2 Replicas) และมี **Persistence Storage (PVC)** สำหรับ Redis
- **Monitoring:** Dashboard 4 กราฟ (Total Pops, Trend, Memory per Pod, Top 5 Players)

---

## 📁 โครงสร้าง Repository

```
k8s-project/
├── backend/                # โค้ด Backend API (Node.js + Redis)
├── frontend/               # โค้ด Frontend Web (Nginx)
├── jenkins/
│   └── build/              # Unified CI/CD Pipelines (Build -> Terraform -> Ansible)
├── Terraform/              # Infrastructure as Code (Kubernetes Provider)
├── ansible/                # Configuration Management (K8s Manifests)
├── k8s/                    # Kubernetes Manifests (PVC, Deployment, Monitoring)
├── prometheus/             # Prometheus Config & RBAC
└── grafana/                # Grafana Dashboards Provisioning
```

---

## 🚀 วิธีการใช้งานระบบ (Full Deployment Guide)

คุณสามารถเลือกใช้งานได้ 2 รูปแบบ ตามความเหมาะสม:

### 1. การรันแบบอัตโนมัติ (Automated CI/CD)
วิธีนี้เหมาะสำหรับการพัฒนาต่อเนื่อง เพียงแค่แก้ไขโค้ดแล้วส่งขึ้น Git:
- **คำสั่ง:** `git push origin ReadMe_noey`
- **สิ่งที่เกิดขึ้น:** Jenkins จะดึงโค้ดไป Build Docker Image ➔ ให้ Terraform เตรียม Namespace ➔ ให้ Ansible Deploy แอป ➔ และทำ Rollout Restart ให้อัตโนมัติ

---

### 2. การติดตั้งครั้งแรกด้วยมือ (Manual Bootstrap)
หากคุณต้องการติดตั้งระบบทั้งหมดใหม่ตั้งแต่ต้น (Clean Install) ให้รันตามลำดับดังนี้:

#### **ขั้นตอนที่ 1: เตรียมโครงสร้างพื้นฐาน (Terraform)**
สร้าง Namespace, ConfigMap และ Secret เตรียมไว้ใน Cluster:
```bash
cd Terraform
terraform init
terraform apply -auto-approve
cd ..
```

#### **ขั้นตอนที่ 2: เตรียมพื้นที่เก็บข้อมูล (Persistence)**
```bash
kubectl apply -f k8s/pvc.yaml
```

#### **ขั้นตอนที่ 3: ติดตั้งแอปพลิเคชัน (Ansible)**
สั่งรัน Redis และใช้ Ansible ติดตั้ง Backend/Frontend:
```bash
# รัน Redis
kubectl apply -f k8s/deployment.yaml

# รัน Backend & Frontend (ผ่าน Ansible)
cd ansible/backend && ansible-playbook -i hosts.ini deploy_backend.yml
cd ../frontend && ansible-playbook -i hosts.ini deploy_frontend.yml
cd ../..
```

#### **ขั้นตอนที่ 4: ติดตั้งระบบ Monitoring**
```bash
kubectl apply -f k8s/monitoring.yaml
kubectl apply -f k8s/monitoring-deployment.yaml
kubectl apply -f prometheus/rbac.yaml
```

---

## 🔍 การตรวจสอบและเข้าใช้งาน
เมื่อรันเสร็จแล้ว ให้เปิด Terminal เพื่อทำ **Port Forward** สำหรับเข้าถึงจากเครื่องตัวเอง:
```bash
# หน้าเว็บ (30001) และ API (30002)
kubectl port-forward svc/frontend 30001:80 -n monkeypop
kubectl port-forward svc/backend 30002:3001 -n monkeypop

# Monitoring (Grafana: 30000, Prometheus: 30090)
kubectl port-forward svc/grafana 30000:3000 -n monkeypop
kubectl port-forward svc/prometheus 30090:9090 -n monkeypop
```

---

## ☸️ Kubernetes Configuration

| Service | Port (Internal) | NodePort | Persistence |
|---------|-----------------|----------|-------------|
| **Frontend** | 80 | 30001 | No |
| **Backend** | 3001 | 30002 | No |
| **Redis** | 6379 | - | **Yes (PVC 1GB)** |
| **Prometheus**| 9090 | 30090 | No |
| **Grafana** | 3000 | 30000 | No |

---

## 📊 Monitoring Dashboard (4 Panels)
1. **Grand Total Pops:** คะแนนรวมทั้งหมดจากผู้เล่นทุกคน
2. **Total Pops Over Time:** กราฟเส้นแสดงแนวโน้มการเติบโตของคะแนน
3. **Memory Usage per Pod:** ติดตามการใช้ RAM ของแต่ละ Pod แยกตาม IP
4. **Top 5 Players:** กราฟแท่งแสดงอันดับผู้เล่นที่ทำคะแนนสูงสุดแบบ Real-time

---

## 📄 ข้อมูลการส่งงาน
- **วิชา:** ENG23 3074 — Serverless and Cloud Architectures
- **อาจารย์ผู้สอน:** ดร. นันทวุฒิ เกาะกุ้ง (AFHEA)
- ภาควิชาวิศวกรรมคอมพิวเตอร์ มหาวิทยาลัยเทคโนโลยีสุรนารี
