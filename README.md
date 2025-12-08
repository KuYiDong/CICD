# AWS 인프라 & CI/CD 프로젝트 포트폴리오

<img src="image/개요.png" alt="설명" width="1000" style="border: 10px solid black; border-radius: 5px;">

# EKS 기반 CI/CD & GitOps 클라우드 인프라 구축 프로젝트

##  Overview
이 프로젝트는 AWS 환경에서 EKS를 중심으로 하는 **클라우드 인프라 운영 환경을 직접 구축한 개인 프로젝트**입니다.  
Terraform 기반 인프라 자동화, GitHub Actions를 활용한 CI/CD 파이프라인, ArgoCD를 통한 GitOps 배포, Prometheus/Grafana 모니터링까지 포함한 **엔드투엔드(End-to-End) 클라우드 구성**을 목표로 합니다.

인프라 → 배포 → 서비스 운영 → 모니터링 전 과정을 실제 운영 환경과 동일한 흐름으로 구성하여 전체 클라우드 운영 사이클을 경험할 수 있게 설계했습니다.

---

##  Architecture

**Terraform**
- VPC, Subnet, Routing, NAT, IGW  
- EKS Cluster & NodeGroup  
- IAM Roles, IRSA 구성  
- ALB Ingress Controller 권한 설정  
- ACM 인증서 + Route53 레코드 구성  

**Kubernetes / AWS**
- ALB Ingress Controller  
- EBS CSI Driver  
- ClusterIP / Ingress 기반 서비스 구성  

**CI/CD**
- GitHub Actions  
- Docker 이미지 빌드 → ECR Push  
- ArgoCD 자동 Sync → EKS 배포  

**Monitoring**
- Prometheus  
- Grafana  
- AlertManager  

---

##  Technology Stack

| Category | Tools |
|---------|-------|
| IaC | Terraform |
| Container | Docker |
| Orchestration | EKS (Kubernetes) |
| CI/CD | GitHub Actions, ECR |
| GitOps | ArgoCD |
| Monitoring | Prometheus, Grafana |
| Networking | ALB Ingress, Route53, ACM |
| Storage | EBS CSI Driver |

---

##  Features

### ✔ Infrastructure as Code
- Terraform으로 AWS 인프라 전체 자동화  
- eksctl 없이 Terraform만으로 EKS 구성  
- 재현 가능한 인프라 제공  

### ✔ GitHub Actions 기반 CI/CD
- push → Docker 빌드 → ECR 자동 업로드  
- 이미지 태그 자동 생성  
- 배포 파이프라인 자동화  

### ✔ GitOps Workflow
- ArgoCD가 Git 저장소 상태를 기준으로 K8s 배포 관리  
- 변경 내역 추적 가능  
- 선언형 배포로 실수 방지  

### ✔ Monitoring Stack
- kube-prometheus-stack 기반 설치  
- Grafana 기본 대시보드 제공  
- Prometheus로 메트릭 수집  
- AlertManager 구성 가능  
- Prometheus/Grafana 데이터 PVC에 영구 저장  

### ✔ HTTPS 처리
- Route53 도메인  
- ACM SSL 인증서  
- ALB Ingress Controller로 HTTPS 종단 처리  

---

##  Repository Structure

```
CICD/
├── terraform_project/            # VPC, EKS, IAM 등 IaC 코드
├── Web_app_CI_CD/            # Kubernetes manifests
├── ingress/                 # Argocd, grafana ingress
├── kube-prometheus-stack    # prometheus, grafana helm
├── .github/workflows/    # GitHub Actions CI/CD 파이프라인
└── README.md
```

---

## CI/CD Workflow

1. 코드 commit/push  
2. GitHub Actions 동작  
   - Docker 이미지 빌드  
   - ECR 업로드  
3. Git 저장소의 manifest 변경 감지  
4. ArgoCD 자동 Sync  
5. EKS로 배포  
6. ALB-Ingress 통해 서비스 노출  

---

## Deployment Guide (요약)

### 1) Infrastructure 배포
```bash
terraform init
terraform plan
terraform apply
```

### 2) Kubernetes 구성
ArgoCD가 manifests 폴더를 기준으로 자동 배포합니다.

### 3) 서비스 접속
Route53에 연결된 도메인 접속 → ALB → EKS 서비스 제공

---

## Monitoring

- Prometheus가 모든 메트릭 수집  
- Grafana에서 대시보드 조회  
- kube-prometheus-stack 기본 템플릿 활용  
- Prometheus / Grafana PV로 데이터 영구 보존  

---

## Project Goal

- AWS 기반 클라우드 인프라 전체 구성 경험  
- Terraform 기반 인프라 자동화 역량 강화  
- GitOps 기반 배포 사이클 경험  
- 모니터링 포함 운영 환경 구축  

---

## Summary

AWS 기반 EKS 클러스터 운영부터 CI/CD 자동화, HTTPS 인프라 구성, 모니터링 환경까지  
실제 서비스 운영에 필요한 핵심 요소를 모두 다루는 개인 프로젝트입니다.  
클라우드 엔지니어 실무와 동일한 구조를 직접 구현하는 데 목적을 두고 있습니다.

