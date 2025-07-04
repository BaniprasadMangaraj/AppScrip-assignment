
# 🚀 CI/CD Infrastructure Setup on AWS using Terraform, Kubernetes, Jenkins, ArgoCD, and Ansible

## 📌 PreRequisites

> \[!IMPORTANT]
> Before you begin setting up this project, make sure the following tools are installed and configured properly on your system:

* Terraform
* AWS CLI
* Ansible
* kubectl
* helm
* git
* SSH Key access to EC2
* IAM User with programmatic access

---

## 🛠️ Setup & Initialization

### 1. Install Terraform

#### Linux & macOS

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

### Verify Installation

```bash
terraform -v
```

---

### 2. Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
```

Configure it:

```bash
aws configure
```

---

### 3. Install Ansible

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

### Verify Ansible Installation

```bash
ansible --version
```

---

## ⚙️ Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/baniprasadmangaraj/appscrip.git
cd terraform
```

### 2. Generate SSH Key

```bash
ssh-keygen -f terra-key
chmod 400 terra-key
```

---

### 3. Initialize Terraform

```bash
terraform init
terraform plan
terraform apply
```

> Confirm with `yes` when prompted.

---

### 4. Access EC2 Instance

```bash
ssh -i terra-key ubuntu@<public-ip>
```

---

### 5. Install Required Applications using Ansible

You can automate the installation of required tools like Docker, Jenkins, kubectl, Helm, etc.

**Example commands**:

```bash
ansible-playbook install-docker.yml -i inventory
ansible-playbook install-jenkins.yml -i inventory
ansible-playbook install-kubetools.yml -i inventory
```

> Make sure your `inventory` file contains the public IP of your EC2 instance.

---

## 🤖 Jenkins Setup

### Check if Jenkins is Running

```bash
sudo systemctl status jenkins
```

### Access Jenkins

* Open in browser: `http://<EC2-Public-IP>:8080`
* Admin password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Install Jenkins Plugins:

* Docker Pipeline
* Pipeline View

---

### Add Global Credentials

#### GitHub Credentials

* Type: Username with Password
* ID: `github-credentials`

#### DockerHub Credentials

* Type: Username with Password
* ID: `docker-hub-credentials`

---

### Configure Shared Library

* Navigate to **Manage Jenkins → Configure System → Global Pipeline Libraries**

  * Name: `shared`
  * Default version: `main`
  * Repo: `https://github.com/<your-username>/jenkins-shared-libraries`

---

### Create Jenkins Pipeline

* Name: `AppScrip`
* Type: Pipeline
* Configure:

  * GitHub Project: `https://github.com/<your-username>/appscrip`
  * Trigger: GitHub hook trigger
  * Pipeline script from SCM

    * Repo URL: `https://github.com/<your-username>/appscrip`
    * Credentials: `github-credentials`
    * Branch: `master`
    * Script Path: `Jenkinsfile`

### GitHub Webhook

* Go to GitHub → Repo → Settings → Webhooks
* Payload URL: `http://<jenkins-server>:8080/github-webhook/`

---

## 🚀 Continuous Deployment using ArgoCD

### SSH into Bastion Server

```bash
ssh -i terra-key ubuntu@<bastion-ip>
```

### Configure AWS CLI & kubeconfig

```bash
aws configure
aws eks --region eu-west-1 update-kubeconfig --name appscrip-cluster
```

---

### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
watch kubectl get pods -n argocd
```

### Change ArgoCD Server Type

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

### Port Forward & Access GUI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address=0.0.0.0 &
```

Visit: `https://<bastion-ip>:8080`

Get Password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

---

### Deploy Application via ArgoCD GUI

* Click “New App”
* Fill in:

  * Name: your-app
  * Project: default
  * Sync Policy: Automatic
* Source:

  * Repo: your GitHub URL
  * Path: `kubernetes`
* Destination:

  * Cluster: [https://kubernetes.default.svc](https://kubernetes.default.svc)
  * Namespace: `appscrip`

---

## 🌐 Ingress Setup with NGINX

```bash
kubectl create namespace ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer
```

Get External IP:

```bash
kubectl get svc -n ingress-nginx
```

---

## 🔐 HTTPS Setup with Cert-Manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.12.0 \
  --set installCRDs=true
```

Check DNS:

```bash
kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

> Update your DNS on GoDaddy (CNAME or A Record) with above hostname.

---

## 🔒 Enable HTTPS in Your Manifests

### 04-configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: appscrip-config
  namespace: appscrip
data:
  MONGODB_URI: "mongodb://mongodb-service:27017/appscrip"
  NODE_ENV: "production"
  NEXT_PUBLIC_API_URL: "https://appscrip.yourdomain.com/api"
  NEXTAUTH_URL: "https://appscrip.yourdomain.com/"
  NEXTAUTH_SECRET: "<secret>"
  JWT_SECRET: "<jwt-secret>"
```

### 10-ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: appscrip-ingress
  namespace: appscrip
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - appscrip.yourdomain.com
      secretName: appscrip-tls
  rules:
    - host: appscrip.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: appscrip-service
                port:
                  number: 80
```

Apply Resources:

```bash
kubectl apply -f 00-cluster-issuer.yaml
kubectl apply -f 04-configmap.yaml
kubectl apply -f 10-ingress.yaml
```

---

## ✅ Verify SSL Certificate Status

```bash
kubectl get certificate -n appscrip
kubectl describe certificate appscrip-tls -n appscrip
kubectl logs -n cert-manager -l app=cert-manager
kubectl get challenges -n appscrip
kubectl describe challenges -n appscrip
```

---

## 🎉 Congratulations!

Your full CI/CD infrastructure is now live and fully automated using:

* Terraform for provisioning
* Jenkins for CI
* Argo CD for CD
* Kubernetes for orchestration
* NGINX + Cert Manager for secure HTTPS access
* Ansible for app installation


