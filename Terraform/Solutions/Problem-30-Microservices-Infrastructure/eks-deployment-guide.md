# EKS Microservices Infrastructure Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying a production-ready EKS cluster with microservices infrastructure including service mesh, monitoring, and CI/CD capabilities.

## Architecture Components

### Core Infrastructure
- **EKS Cluster**: Managed Kubernetes service with version 1.28
- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **Node Groups**: Managed node groups with auto-scaling
- **IAM Roles**: Proper RBAC and service account configurations

### Service Mesh
- **Istio**: Complete service mesh with traffic management
- **Ingress Gateway**: External traffic routing
- **Sidecar Injection**: Automatic proxy injection

### Monitoring Stack
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **CloudWatch**: AWS native monitoring integration

### Load Balancing
- **AWS Load Balancer Controller**: Native AWS ALB/NLB integration
- **Ingress Controllers**: Traffic routing and SSL termination

## Prerequisites

### Required Tools
```bash
# Install required CLI tools
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### AWS Permissions
Required IAM permissions for deployment:
- EKS cluster management
- VPC and networking resources
- IAM role and policy management
- EC2 instance management
- Load balancer management

## Deployment Steps

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Plan Deployment
```bash
terraform plan -var-file="terraform.tfvars"
```

### Step 3: Deploy Infrastructure
```bash
terraform apply -var-file="terraform.tfvars"
```

### Step 4: Configure kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name microservices-cluster
```

### Step 5: Verify Deployment
```bash
# Check cluster status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check Istio installation
kubectl get pods -n istio-system

# Check monitoring stack
kubectl get pods -n monitoring
```

## Post-Deployment Configuration

### Configure Istio Service Mesh

#### Enable Istio Injection
```bash
kubectl label namespace microservices istio-injection=enabled
```

#### Deploy Sample Application with Istio
```yaml
apiVersion: v1
kind: Service
metadata:
  name: productpage
  namespace: microservices
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: productpage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productpage-v1
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: productpage
      version: v1
  template:
    metadata:
      labels:
        app: productpage
        version: v1
    spec:
      containers:
      - name: productpage
        image: docker.io/istio/examples-bookinfo-productpage-v1:1.17.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
```

#### Configure Istio Gateway
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: microservices-gateway
  namespace: microservices
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: microservices
  namespace: microservices
spec:
  hosts:
  - "*"
  gateways:
  - microservices-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    route:
    - destination:
        host: productpage
        port:
          number: 9080
```

### Configure Monitoring

#### Access Grafana Dashboard
```bash
# Get Grafana service external IP
kubectl get svc -n monitoring prometheus-grafana

# Port forward for local access
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Default credentials:
- Username: admin
- Password: (as configured in terraform.tfvars)

#### Access Prometheus
```bash
# Get Prometheus service external IP
kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus

# Port forward for local access
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

### Configure Auto-scaling

#### Cluster Autoscaler
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.0
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/microservices-cluster
```

## Security Best Practices

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: microservices
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: microservices
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: microservices
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: microservices
```

### Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservices
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## Troubleshooting

### Common Issues

#### EKS Cluster Access Issues
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name microservices-cluster

# Check AWS credentials
aws sts get-caller-identity

# Verify cluster status
aws eks describe-cluster --name microservices-cluster --region us-west-2
```

#### Node Group Issues
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name microservices-cluster --nodegroup-name microservices-cluster-nodes --region us-west-2

# Check node status
kubectl get nodes -o wide

# Check node logs
kubectl describe node <node-name>
```

#### Istio Issues
```bash
# Check Istio installation
istioctl verify-install

# Check proxy status
istioctl proxy-status

# Check configuration
istioctl analyze
```

#### Monitoring Issues
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Navigate to http://localhost:9090/targets

# Check Grafana datasources
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Navigate to http://localhost:3000
```

## Maintenance

### Regular Tasks

#### Update EKS Cluster
```bash
# Update cluster version
aws eks update-cluster-version --name microservices-cluster --kubernetes-version 1.29 --region us-west-2

# Update node group
aws eks update-nodegroup-version --cluster-name microservices-cluster --nodegroup-name microservices-cluster-nodes --region us-west-2
```

#### Update Helm Charts
```bash
# Update repositories
helm repo update

# Upgrade Istio
helm upgrade istio-base istio/base -n istio-system
helm upgrade istiod istio/istiod -n istio-system

# Upgrade monitoring stack
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

#### Backup and Recovery
```bash
# Backup cluster configuration
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Backup persistent volumes
kubectl get pv -o yaml > pv-backup.yaml

# Backup secrets
kubectl get secrets --all-namespaces -o yaml > secrets-backup.yaml
```

## Cost Optimization

### Resource Management
- Use spot instances for non-critical workloads
- Implement proper resource requests and limits
- Use horizontal pod autoscaling
- Monitor and optimize storage usage

### Monitoring Costs
```bash
# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Use AWS Cost Explorer for detailed cost analysis
aws ce get-cost-and-usage --time-period Start=2023-01-01,End=2023-12-31 --granularity MONTHLY --metrics BlendedCost
```

## Conclusion

This EKS microservices infrastructure provides a robust foundation for running containerized applications at scale. The combination of Kubernetes, Istio service mesh, and comprehensive monitoring ensures high availability, security, and observability for your microservices architecture.
