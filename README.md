
# 3tier-Architecture-Terraform
![이미지 추가](images/3tier-아키텍쳐.png)


## 개요
해당 프로젝트는 Terraform을 활용해 AWS 환경에 3계층(3-Tier) 아키텍처를 구축하였습니다. 해당 구성은 서비스의 확장성과 안정성을 고려하여 설계되었으며, 애플리케이션을 다음과 같은 세 가지 계층으로 나누어 구성합니다.

1. 프레젠테이션 계층 (웹 계층):
사용자와 직접 맞닿는 계층으로, 주로 웹 브라우저나 모바일이 해당 기능을 담당합니다. 해당 프로젝트에서는 웹 서버가 해당 역할을 담당합니다.

2. 애플리케이션 계층 (앱 계층):
비즈니스 로직을 처리하는 중간 계층입니다. 프레젠테이션 계층으로부터 요청을 받아 필요한 작업을 수행하고, 데이터 계층과의 연결을 통해 결과를 반환합니다.

3. 데이터 계층 (데이터베이스 계층):
애플리케이션에서 사용하는 데이터를 저장하고 관리하는 계층입니다. 주로 RDS와 같은 관계형 데이터베이스를 사용하며, 앱 계층의 요청에 따라 데이터를 조회하거나 수정합니다.

Terraform은 AWS 리소스를 코드로 관리할 수 있도록 도와주는 인프라 자동화 도구입니다. 반복 가능한 구성과 명확한 변경 이력을 바탕으로 효율적인 협업, 안정적인 배포, 유지보수의 용이성을 제공합니다. 이 프로젝트에서는 Terraform을 통해 네트워크, 보안 그룹, EC2, ALB, RDS 등 다양한 AWS 리소스를 자동으로 구축하고 관리할 수 있습니다.
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

