
# AWS 인프라 & CI/CD 프로젝트 포트폴리오
![이미지 추가](images/3tier-아키텍쳐.png)


## 개요
# 프로젝트 개요

해당 프로젝트는 **Terraform과 ArgoCD를 활용하여 클라우드 환경에서 Kubernetes(EKS) 기반 인프라를 자동으로 구축하고, CI/CD 및 모니터링까지 통합 관리하는 프로젝트**입니다.

---

## 주요 구성 및 특징

### 1. 인프라 자동화 (Terraform)
- VPC, 서브넷, 라우팅 등 기본 네트워크 환경과 EKS 클러스터를 코드 기반으로 자동 구축
- AWS ALB Controller, EBS CSI Driver 등 추가 기능을 포함하여:
  - 서비스별 외부 접속(ALB + Route53)
  - 쿠버네티스 내 영구 저장소(EBS PV) 구성
- **효율성**: 반복적인 인프라 구성 과정을 자동화하여 인적 오류 최소화, 인프라 배포 시간 단축

### 2. CI/CD 파이프라인 (GitHub Actions + ECR + ArgoCD)
- 개발자가 Git에 Push 하면 GitHub Actions가 이미지를 빌드 후 ECR에 Push
- ArgoCD가 Git 상태를 감시하고, 변경 사항을 클러스터에 자동 동기화
- **효율성**: 수동 배포 없이 코드 변경이 즉시 클러스터에 반영되어 운영과 개발 간의 빠른 피드백 루프 형성

### 3. 모니터링 및 관찰 가능성 (Prometheus + Grafana)
- 클러스터 및 서비스의 상태, 성능, 알람을 자동으로 모니터링
- 알람과 대시보드 구성으로 운영 리스크 최소화
- **효율성**: 문제 발생 시 즉시 대응 가능, 장기적인 시스템 안정성 확보

---

## 프로젝트 장점
- **Infrastructure as Code(IaC)**: 재현 가능한 인프라 구축 가능
- **GitOps 기반 관리**: 배포 및 업데이트 과정의 투명성 확보, 버전 관리 용이
- **자동화와 모니터링 통합**: 인프라와 애플리케이션 관리 효율 극대화
- **운영 안정성 향상**: 외부 접속, 스토리지, 알람 체계가 통합 관리되어 장애 대응 속도 향상

<br><br>


## Terraform 구성 파일

- **modules/**  
  재사용 가능한 Terraform 모듈들이 위치한 폴더입니다.  
  - **web_alb/**: 외부용 Application Load Balancer(ALB) 구성을 담당합니다.
  - **was_alb/**: 내부용 Application Load Balancer(ALB) 구성을 담당합니다. 
  - **front_asg/**: Auto Scaling Group 및 Launch Template 관련 리소스를 관리합니다.
  - **back_asg/**: Auto Scaling Group 및 Launch Template 관련 리소스를 관리합니다. 
  - **RDS/**: RDS 인스턴스 및 클러스터를 구성합니다.  
  - **security-group/**: 웹, 앱, 데이터베이스 계층별 보안 그룹(Security Group)을 정의합니다.

- **envs/**  
  실제 배포 환경별 설정을 관리하는 디렉토리입니다.  
  - **prod/**: 운영 환경에 대한 설정을 포함하며, 여기서 전체 인프라 구성이 이뤄집니다.  
    - **main.tf**: VPC, 서브넷, 인터넷 게이트웨이(IGW), NAT 게이트웨이 등 네트워크 리소스를 정의합니다. 위의 모듈들을 불러와 전체 인프라를 구성하는 메인 Terraform 파일입니다.  
    - **variables.tf**: 운영 환경에서 사용할 변수들을 정의합니다.  
    - **outputs.tf**: 배포 완료 후 출력할 정보(예: ALB DNS, RDS 엔드포인트 등)를 정의합니다.  
  
- **provider.tf**  
  AWS 프로바이더를 설정하고, 기본 리전(region) 등 공통 프로바이더 설정을 정의하는 파일입니다.
<br><br>


### Terraform을 사용하여 인프라 배포
<pre>terraform init 
terraform plan 
terraform apply </pre>


<br><br>

## AWS 리소스
### VPC  
**[리소스 맵]**  
<br>
<img src="images/vpc_리소스맵.png" alt="리소스맵" width="800"/>  
<br><br>

**[서브넷]**  
<br>
<img src="images/Subnet.png" alt="서브넷" width="800"/>  
<br>

- **총 8개 서브넷**
  - 퍼블릭 서브넷 2개
  - 프라이빗 서브넷 6개
    - WAS & WEB 서브넷 4개
    - Database 서브넷 2개
<br>

### 보안 그룹

| 보안 그룹 이름    | 인바운드 포트 | 출발지        | 목적                    |
|------------------|----------------|----------------|-------------------------|
| **bastion_host** | 22 (SSH)       | `0.0.0.0/0`    | 외부에서 Bastion으로 SSH 접속 |
| **ext_alb_sg**   | 80, 443        | `0.0.0.0/0`    | 외부 사용자용 ALB       |
| **web_sg**       | 80             | `ext_alb_sg`   | ALB → Web 서버           |
| **int_alb_sg**   | 8080           | `web_sg`       | Web → 내부 ALB          |
| **was_sg**       | 8080           | `int_alb_sg`   | 내부 ALB → WAS 서버      |
| **db_sg**        | 3306           | `was_sg`       | WAS 서버 → RDS DB       |


<br><br>

### EC2  
<img src="images/EC2.png" alt="EC2" width="600"/>  
<br><br>

---

### ALB  
<img src="images/ALB.png" alt="ALB" width="600"/>  
<br>

- **Web_alb**: 웹서버를 대상으로 로드 밸런싱
- **Was_alb**: 어플리케이션 서버를 대상으로 로드 밸런싱

<br><br>

**[Web_ALB_Target_group]**  
<img src="images/ALB_TG1.png" alt="Web-tg" width="600"/>  
<br><br>

**[Was_ALB_Target_group]**  
<img src="images/ALB_TG.png" alt="Was-tg" width="600"/>  
<br><br>

---

### ASG  
<img src="images/ASG_image2.png" alt="Web ASG" width="600"/>  
<br><br>
<img src="images/ASG_image.png" alt="Was ASG" width="600"/>  
<br><br>

---

### RDS  
<img src="images/RDS.png" alt="RDS" width="600"/>  
<br>

- **Multi-AZ 구성**으로 장애 시 자동 Failover
- 백업 보존 기간: 최대 7일

