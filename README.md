
# AWS 인프라 & CI/CD 프로젝트 포트폴리오
![이미지 추가](images/3tier-아키텍쳐.png)


## 개요
# 프로젝트 개요

해당 프로젝트는 Terraform과 ArgoCD를 활용하여 클라우드 환경에서 Kubernetes(EKS) 기반 인프라를 자동으로 구축하고, CI/CD 및 모니터링까지 통합 관리하는 프로젝트입니다.

Infrastructure as Code(IaC)를 통하여 인프라를 코드 형식으로 관리하며 자동화를 통하여 인프라를 배포합니다. GitOps 기반 관리릂통하여 배포 및 업데이트 과정의 투명성 확보하며 버전 관리 용이해집니다.Grafana와 Prometheus를 통해 쿠버네티스 내의 서비스 상태와 성능을 실시간으로 모니터링하며 CI/CD 파이프라인을 통해 개발자가 Git에 Push 하면 GitHub Actions가 이미지를 빌드 후 ECR에 Push 및 감지를 통해 실시간으로 변동 사항을 감지하여 언제나 최산화된 설정을 유지할 수 있습니다.

해당 프로젝트는 전체 자동화 구성이 아니기에 반드시 Read.me을 참고하여 Argocd 및 기타 리소스에 대한 설정을 하셔야 합니다.

<br><br>

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



## 프로젝트 장점
- **Infrastructure as Code(IaC)**: 재현 가능한 인프라 구축 가능
- **GitOps 기반 관리**: 배포 및 업데이트 과정의 투명성 확보, 버전 관리 용이
- **자동화와 모니터링 통합**: 인프라와 애플리케이션 관리 효율 극대화
- **운영 안정성 향상**: 외부 접속, 스토리지, 알람 체계가 통합 관리되어 장애 대응 속도 향상

<br><br>


### Terraform을 사용하여 인프라 배포
<pre>terraform init 
terraform plan 
terraform apply </pre>


<br><br>

## 1. ALB-Controller & EBS-CSI-Driver
### 1.1 ALB-Controller 설치
**[DNS 연]**
<pre>aws eks --region ap-northeast-2 update-kubeconfig --name $Cluster </pre>
**[ALB Controller용 IAM Policy 생성]**
<pre>curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json


aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json </pre>
**[IAM ServiceAccount 생성]**
<pre>eksctl utils associate-iam-oidc-provider --cluster $Cluster --approve

eksctl create iamserviceaccount \
  --cluster=$Cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$Account:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve</pre>
**[생성 확인]**
<pre>kubectl get sa aws-load-balancer-controller -n kube-system -o yaml | grep role-arn</pre>

**[AWS-Controller 설치]**
<pre>helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$Cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-northeast-2 \
  --set vpcId=$(aws eks describe-cluster --name $Cluster --query "cluster.resourcesVpcConfig.vpcId" --output text)
</pre>
<br>

### 2. EBS-CSI-Driver 설치
**[IAM Role 생성]**

**[EBS-CSI-Driver 설치]**

---
<br><br>

## ArgoCD 
**[Argocd 설치]**

필수 수정 사항 
1. `argocd argocd-cmd-params-cm` Configmaps insecure 수정
2. `argocd-cm`에서 토큰용 사용자 추가
<pre>helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd -n argocd </pre>

**[HTTPS 비활성화]**
<pre>k edit configmaps -n argocd argocd-cmd-params-cm

apiVersion: v1
data:
  server.insecure: "true" #HTTPS 비활성화</pre>
- argocd는 기본적으로 https을 지원하기 때문에 비활성화 진행

**[유저 생성]**
<pre>k edit configmaps -n argocd argocd-cm

apiVersion: v1
data:
  accounts.devops: apiKey,login</pre>
- admin 계정으로는 token 생성이 불가능하기 때문에 별도의 유저 계정 새성

**[repository 연결]**


**[application 등록]**

---
## CI|CD 파이프라인 등록
**[git_repo 생성&Secret 등록]**

**[ECR_repo 생성]**

**[git push]**

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


