# 🚀 **KUBERNETES E-COMMERCE PROJECT REFERENCE GUIDE**
## **Your Complete Command & Configuration Bible**

---

## 📋 **TABLE OF CONTENTS**

1. [🚀 Quick Commands Reference](#-quick-commands-reference)
2. [📝 Configuration Templates](#-configuration-templates)
3. [🔧 Troubleshooting Guide](#-troubleshooting-guide)
4. [🔒 Security Validation Checklists](#-security-validation-checklists)
5. [⚡ Performance Tuning](#-performance-tuning)
6. [📊 Monitoring Commands](#-monitoring-commands)
7. [🏛️ Compliance Reference](#️-compliance-reference)
8. [🛠️ Development Tools](#️-development-tools)

---

## 🚀 **QUICK COMMANDS REFERENCE**

### **Docker Commands**

```bash
# Build Images
docker build -t ecommerce-frontend:latest .
docker build -t ecommerce-backend:latest .
docker build -t ecommerce-db:latest .

# Run Containers
docker run -p 3000:3000 ecommerce-frontend
docker run -p 8000:8000 ecommerce-backend
docker run -p 5432:5432 ecommerce-db

# Security Scanning
trivy image ecommerce-frontend:latest
trivy image ecommerce-backend:latest
trivy image ecommerce-db:latest

# Docker Compose
docker-compose up -d
docker-compose down
docker-compose logs -f
```

### **Kubernetes Commands**

```bash
# Cluster Management
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# Deployments
kubectl apply -f deployment.yaml
kubectl get deployments
kubectl scale deployment frontend --replicas=3
kubectl rollout status deployment/frontend

# Services
kubectl get services
kubectl expose deployment frontend --port=3000 --type=NodePort
kubectl port-forward service/frontend 3000:3000

# Debugging
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash
kubectl top pods
```

### **Helm Commands**

```bash
# Install Helm Charts
helm install prometheus prometheus-community/kube-prometheus-stack
helm install grafana grafana/grafana
helm install elasticsearch elastic/elasticsearch
helm install istio istio/istio

# Manage Releases
helm list
helm upgrade prometheus prometheus-community/kube-prometheus-stack
helm uninstall prometheus
```

### **Istio Commands**

```bash
# Service Mesh Management
istioctl install --set values.defaultRevision=default
istioctl proxy-status
istioctl proxy-config cluster <pod-name>

# Traffic Management
istioctl analyze
kubectl apply -f virtual-service.yaml
kubectl apply -f destination-rule.yaml
```

---

## 📝 **CONFIGURATION TEMPLATES**

### **Security-Hardened Deployment Template**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-frontend
  namespace: ecommerce
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ecommerce-frontend
  template:
    metadata:
      labels:
        app: ecommerce-frontend
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: frontend
        image: ecommerce-frontend:latest
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

### **Network Policy Template**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ecommerce-network-policy
  namespace: ecommerce
spec:
  podSelector:
    matchLabels:
      app: ecommerce-frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: ecommerce-backend
    ports:
    - protocol: TCP
      port: 8000
```

### **RBAC Configuration Template**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecommerce-backend-sa
  namespace: ecommerce
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ecommerce
  name: ecommerce-backend-role
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ecommerce-backend-binding
  namespace: ecommerce
subjects:
- kind: ServiceAccount
  name: ecommerce-backend-sa
  namespace: ecommerce
roleRef:
  kind: Role
  name: ecommerce-backend-role
  apiGroup: rbac.authorization.k8s.io
```

### **Ingress Security Template**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-secure-ingress
  namespace: ecommerce
  annotations:
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
      SecRule REQUEST_URI "@contains /api/payment" \
        "id:1001,phase:1,block,msg:'Payment endpoint protection'"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;
spec:
  tls:
  - hosts:
    - shyammoahn.shop
    secretName: ecommerce-tls
  rules:
  - host: shyammoahn.shop
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ecommerce-frontend
            port:
              number: 3000
```

---

## 🔧 **TROUBLESHOOTING GUIDE**

### **Common Issues & Solutions**

#### **Pod Startup Failures**

```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Common fixes
kubectl delete pod <pod-name>  # Force restart
kubectl apply -f deployment.yaml  # Reapply config
```

#### **Network Connectivity Issues**

```bash
# Check services
kubectl get services
kubectl describe service <service-name>

# Test connectivity
kubectl exec -it <pod-name> -- curl <service-name>:<port>
kubectl port-forward service/<service-name> 8080:80

# Check network policies
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>
```

#### **Security Policy Violations**

```bash
# Check security contexts
kubectl describe pod <pod-name> | grep -A 10 Security

# Check RBAC
kubectl auth can-i get pods --as=system:serviceaccount:ecommerce:backend-sa
kubectl get rolebindings
kubectl describe rolebinding <binding-name>

# Check admission controllers
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations
```

#### **Performance Bottlenecks**

```bash
# Check resource usage
kubectl top pods
kubectl top nodes
kubectl describe node <node-name>

# Check HPA
kubectl get hpa
kubectl describe hpa <hpa-name>

# Check metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods
```

#### **SSL Certificate Problems**

```bash
# Check certificates
kubectl get certificates
kubectl describe certificate <cert-name>

# Check cert-manager
kubectl get pods -n cert-manager
kubectl logs -n cert-manager <cert-manager-pod>

# Test SSL
openssl s_client -connect shyammoahn.shop:443 -servername shyammoahn.shop
```

---

## 🔒 **SECURITY VALIDATION CHECKLISTS**

### **Pre-Production Security Checklist**

- [ ] **Container Security**
  - [ ] All images scanned with Trivy (0 critical vulnerabilities)
  - [ ] Non-root users configured
  - [ ] Read-only root filesystem enabled
  - [ ] Unnecessary capabilities dropped
  - [ ] Security contexts configured

- [ ] **Kubernetes Security**
  - [ ] RBAC properly configured
  - [ ] Network policies implemented
  - [ ] Pod security standards enforced
  - [ ] Secrets properly managed
  - [ ] Admission controllers enabled

- [ ] **Network Security**
  - [ ] TLS/SSL encryption enabled
  - [ ] WAF configured and active
  - [ ] DDoS protection enabled
  - [ ] Security headers implemented
  - [ ] Rate limiting configured

- [ ] **Compliance**
  - [ ] PCI DSS requirements met
  - [ ] GDPR compliance validated
  - [ ] SOC 2 controls implemented
  - [ ] Security documentation complete
  - [ ] Incident response plan tested

### **Security Scanning Commands**

```bash
# Container Image Scanning
trivy image ecommerce-frontend:latest
trivy image ecommerce-backend:latest
trivy image ecommerce-db:latest

# Kubernetes Cluster Scanning
trivy k8s cluster
kube-hunter --remote <cluster-ip>
kube-bench run

# Application Scanning
trivy fs .
trivy config .
```

### **Vulnerability Management**

```bash
# Check for updates
trivy image --update-db
kubectl get pods -n kube-system

# Update base images
docker pull node:18-alpine
docker pull python:3.11-slim
docker pull postgres:15-alpine

# Apply security patches
kubectl rollout restart deployment/frontend
kubectl rollout restart deployment/backend
```

---

## ⚡ **PERFORMANCE TUNING**

### **Resource Optimization**

```bash
# Check resource usage
kubectl top pods
kubectl top nodes
kubectl describe node <node-name>

# Set resource limits
kubectl patch deployment frontend -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","resources":{"limits":{"memory":"256Mi","cpu":"200m"}}}]}}}}'

# Enable HPA
kubectl autoscale deployment frontend --cpu-percent=70 --min=2 --max=10
```

### **Performance Monitoring**

```bash
# Check metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes

# Check Prometheus metrics
kubectl port-forward service/prometheus-server 9090:80
# Access: http://localhost:9090

# Check Grafana
kubectl port-forward service/grafana 3000:80
# Access: http://localhost:3000
```

---

## 📊 **MONITORING COMMANDS**

### **Prometheus Commands**

```bash
# Access Prometheus
kubectl port-forward service/prometheus-server 9090:80

# Check targets
curl http://localhost:9090/api/v1/targets

# Query metrics
curl "http://localhost:9090/api/v1/query?query=up"
```

### **Grafana Commands**

```bash
# Access Grafana
kubectl port-forward service/grafana 3000:80

# Get admin password
kubectl get secret grafana-admin -o jsonpath="{.data.password}" | base64 -d
```

### **ELK Stack Commands**

```bash
# Access Elasticsearch
kubectl port-forward service/elasticsearch-master 9200:9200

# Check cluster health
curl http://localhost:9200/_cluster/health

# Access Kibana
kubectl port-forward service/kibana-kb-http 5601:5601
```

### **Jaeger Commands**

```bash
# Access Jaeger
kubectl port-forward service/jaeger-query 16686:80

# Check traces
curl http://localhost:16686/api/traces
```

---

## 🏛️ **COMPLIANCE REFERENCE**

### **PCI DSS Level 1 Checklist**

- [ ] **Build and Maintain Secure Networks**
  - [ ] Firewall configuration
  - [ ] Default passwords changed
  - [ ] Network segmentation

- [ ] **Protect Cardholder Data**
  - [ ] Data encryption in transit
  - [ ] Data encryption at rest
  - [ ] Data masking/tokenization

- [ ] **Maintain Vulnerability Management**
  - [ ] Anti-virus software
  - [ ] Secure systems and applications
  - [ ] Regular security updates

- [ ] **Implement Strong Access Control**
  - [ ] Access control measures
  - [ ] Unique IDs for access
  - [ ] Physical access restrictions

- [ ] **Regularly Monitor Networks**
  - [ ] Network monitoring
  - [ ] Log monitoring
  - [ ] Security testing

### **GDPR Compliance Checklist**

- [ ] **Lawfulness of Processing**
  - [ ] Legal basis identified
  - [ ] Consent management
  - [ ] Data minimization

- [ ] **Data Subject Rights**
  - [ ] Right to access
  - [ ] Right to rectification
  - [ ] Right to erasure
  - [ ] Right to portability

- [ ] **Data Protection**
  - [ ] Encryption
  - [ ] Pseudonymization
  - [ ] Access controls
  - [ ] Data breach notification

### **SOC 2 Type II Checklist**

- [ ] **Security**
  - [ ] Access controls
  - [ ] Network security
  - [ ] Vulnerability management

- [ ] **Availability**
  - [ ] System monitoring
  - [ ] Incident response
  - [ ] Business continuity

- [ ] **Confidentiality**
  - [ ] Data classification
  - [ ] Access restrictions
  - [ ] Encryption

---

## 🛠️ **DEVELOPMENT TOOLS**

### **Useful kubectl Aliases**

```bash
# Add to ~/.bashrc or ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
```

### **Development Workflow**

```bash
# Local development
docker-compose up -d
docker-compose logs -f

# Deploy to cluster
kubectl apply -f k8s/
kubectl get pods -w

# Debug
kubectl port-forward service/frontend 3000:3000
kubectl port-forward service/backend 8000:8000
```

### **Useful Scripts**

```bash
# Quick cluster status
#!/bin/bash
echo "=== Cluster Status ==="
kubectl get nodes
echo "=== Pods ==="
kubectl get pods --all-namespaces
echo "=== Services ==="
kubectl get services --all-namespaces
```

---

## 📚 **ADDITIONAL RESOURCES**

### **Documentation Links**
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Helm Documentation](https://helm.sh/docs/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### **Security Resources**
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Falco Documentation](https://falco.org/docs/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Kyverno Documentation](https://kyverno.io/docs/)

### **Compliance Resources**
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)
- [GDPR Guidelines](https://gdpr.eu/)
- [SOC 2 Framework](https://www.aicpa.org/interestareas/frc/assuranceadvisoryservices/aicpasoc2report)

---

## 🎯 **QUICK START CHECKLIST**

### **Before Starting Each Week**
- [ ] Review the main learning plan
- [ ] Check this reference guide
- [ ] Ensure cluster is running
- [ ] Verify security tools are installed

### **After Completing Each Week**
- [ ] Run security scans
- [ ] Test all functionality
- [ ] Update documentation
- [ ] Backup configurations

---

**🚀 This reference guide is your companion throughout the entire 10-week journey. Keep it handy and refer to it whenever you need quick commands, configurations, or troubleshooting help!**
