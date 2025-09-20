# Comprehensive Kubernetes Mastery Guide

## 🎯 Introduction to Kubernetes Architecture and Fundamentals

Kubernetes has become the de facto standard for container orchestration, transforming how we deploy, scale, and manage applications. This comprehensive guide provides deep theoretical understanding combined with practical implementation patterns using Terraform to provision and manage Kubernetes infrastructure.

## 🏗️ Kubernetes Architecture Deep Dive

### Control Plane Components
Understanding the control plane is crucial for effective Kubernetes management:

#### 1. **API Server (kube-apiserver)**
The central management entity that exposes the Kubernetes API:

```yaml
# API Server configuration concepts
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-apiserver-config
data:
  # Authentication and authorization
  enable-admission-plugins: "NodeRestriction,ResourceQuota,PodSecurityPolicy"
  audit-log-maxage: "30"
  audit-log-maxbackup: "10"
  audit-log-maxsize: "100"
  
  # Security configurations
  tls-cert-file: "/etc/kubernetes/pki/apiserver.crt"
  tls-private-key-file: "/etc/kubernetes/pki/apiserver.key"
  client-ca-file: "/etc/kubernetes/pki/ca.crt"
```

**Key Responsibilities**:
- API endpoint exposure and validation
- Authentication and authorization
- Admission control and validation
- Resource state persistence to etcd

#### 2. **etcd - The Cluster Database**
Distributed key-value store that maintains cluster state:

```hcl
# Terraform configuration for etcd cluster
resource "aws_instance" "etcd_nodes" {
  count                  = 3
  ami                    = var.etcd_ami
  instance_type          = "m5.large"
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.etcd.id]
  subnet_id             = var.private_subnet_ids[count.index]

  user_data = templatefile("${path.module}/templates/etcd-init.sh", {
    cluster_name = var.cluster_name
    node_index   = count.index
    etcd_nodes   = aws_instance.etcd_nodes[*].private_ip
  })

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-etcd-${count.index + 1}"
    Role = "etcd"
  })
}
```

**Critical Characteristics**:
- Strongly consistent, distributed key-value store
- Implements Raft consensus algorithm
- Stores all cluster configuration and state
- Requires odd number of nodes (3, 5, 7) for quorum

#### 3. **Controller Manager (kube-controller-manager)**
Runs controller processes that regulate cluster state:

```yaml
# Example controller configuration
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: custom-controller
  template:
    metadata:
      labels:
        app: custom-controller
    spec:
      containers:
      - name: controller
        image: custom-controller:v1.0.0
        env:
        - name: RECONCILE_INTERVAL
          value: "30s"
        - name: MAX_CONCURRENT_RECONCILES
          value: "5"
```

**Key Controllers**:
- **Node Controller**: Monitors node health and availability
- **Replication Controller**: Maintains desired pod replica counts
- **Endpoints Controller**: Manages service endpoints
- **Service Account Controller**: Creates default service accounts

#### 4. **Scheduler (kube-scheduler)**
Assigns pods to nodes based on resource requirements and constraints:

```yaml
# Scheduler configuration and policies
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: default-scheduler
  plugins:
    score:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
      - name: PodTopologySpread
  pluginConfig:
  - name: NodeResourcesFit
    args:
      scoringStrategy:
        type: LeastAllocated
```

**Scheduling Process**:
1. **Filtering**: Eliminate unsuitable nodes
2. **Scoring**: Rank suitable nodes
3. **Binding**: Assign pod to highest-scoring node

### Worker Node Components

#### 1. **kubelet - Node Agent**
Primary node agent that manages pod lifecycle:

```hcl
# Terraform configuration for worker nodes
resource "aws_launch_template" "worker_nodes" {
  name_prefix   = "${var.cluster_name}-worker-"
  image_id      = var.worker_ami
  instance_type = var.worker_instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.worker_nodes.id]

  user_data = base64encode(templatefile("${path.module}/templates/worker-init.sh", {
    cluster_name     = var.cluster_name
    cluster_endpoint = aws_eks_cluster.main.endpoint
    cluster_ca       = aws_eks_cluster.main.certificate_authority[0].data
    node_group_name  = var.node_group_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.cluster_name}-worker"
      Role = "worker"
    })
  }
}
```

**kubelet Responsibilities**:
- Pod lifecycle management
- Container runtime interface (CRI) communication
- Resource monitoring and reporting
- Volume mounting and management

#### 2. **Container Runtime**
Manages container execution and lifecycle:

```yaml
# Container runtime configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: containerd-config
data:
  config.toml: |
    version = 2
    [plugins."io.containerd.grpc.v1.cri"]
      sandbox_image = "k8s.gcr.io/pause:3.7"
      [plugins."io.containerd.grpc.v1.cri".containerd]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
            runtime_type = "io.containerd.runc.v2"
```

**Supported Runtimes**:
- **containerd**: Industry-standard container runtime
- **CRI-O**: Lightweight container runtime for Kubernetes
- **Docker**: Traditional container runtime (deprecated in K8s 1.24+)

#### 3. **kube-proxy - Network Proxy**
Maintains network rules and enables service communication:

```yaml
# kube-proxy configuration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "iptables"
clusterCIDR: "10.244.0.0/16"
iptables:
  masqueradeAll: false
  masqueradeBit: 14
  minSyncPeriod: 0s
  syncPeriod: 30s
ipvs:
  strictARP: false
  scheduler: "rr"
```

## 🔧 Core Kubernetes Objects and Resources

### 1. **Pods - The Atomic Unit**
Smallest deployable unit in Kubernetes:

```yaml
# Production-ready pod specification
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  labels:
    app: web-app
    version: v1.0.0
    environment: production
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
spec:
  # Security context
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  
  # Resource management
  containers:
  - name: web-app
    image: nginx:1.21-alpine
    ports:
    - containerPort: 80
      name: http
    
    # Resource requests and limits
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    
    # Health checks
    livenessProbe:
      httpGet:
        path: /health
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 10
    
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
    
    # Environment configuration
    env:
    - name: APP_ENV
      value: "production"
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
  
  # Restart policy
  restartPolicy: Always
  
  # Node selection
  nodeSelector:
    kubernetes.io/arch: amd64
  
  # Tolerations for node taints
  tolerations:
  - key: "app"
    operator: "Equal"
    value: "web"
    effect: "NoSchedule"
```

### 2. **Deployments - Declarative Updates**
Manages replica sets and provides declarative updates:

```yaml
# Advanced deployment configuration
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-deployment
  labels:
    app: web-app
spec:
  # Replica management
  replicas: 3
  
  # Update strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  
  # Pod selection
  selector:
    matchLabels:
      app: web-app
  
  # Pod template
  template:
    metadata:
      labels:
        app: web-app
        version: v1.0.0
    spec:
      containers:
      - name: web-app
        image: web-app:v1.0.0
        ports:
        - containerPort: 8080
        
        # Advanced resource management
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        
        # Comprehensive health checks
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
```

### 3. **Services - Network Abstraction**
Provides stable network endpoint for pods:

```yaml
# Comprehensive service configuration
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  labels:
    app: web-app
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  type: LoadBalancer
  
  # Port configuration
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 8443
    protocol: TCP
  
  # Pod selection
  selector:
    app: web-app
  
  # Session affinity
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

### 4. **ConfigMaps and Secrets**
Configuration and sensitive data management:

```yaml
# ConfigMap for application configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.properties: |
    server.port=8080
    logging.level.root=INFO
    spring.profiles.active=production
  nginx.conf: |
    server {
        listen 80;
        location / {
            proxy_pass http://backend:8080;
        }
    }

---
# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database-url: cG9zdGdyZXNxbDovL3VzZXI6cGFzc0BkYi5leGFtcGxlLmNvbS9teWRi
  api-key: YWJjZGVmZ2hpams=
```

## 🔐 Advanced Kubernetes Security Patterns

### 1. **Pod Security Standards**
Implementing comprehensive pod security:

```yaml
# Pod Security Policy (deprecated) replacement with Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

---
# Security Context Constraints
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    # Run as non-root user
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    
    # Security enhancements
    seccompProfile:
      type: RuntimeDefault
    supplementalGroups: [1000]
  
  containers:
  - name: app
    image: app:secure
    securityContext:
      # Container-level security
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
```

### 2. **Network Policies**
Implementing micro-segmentation:

```yaml
# Comprehensive network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-app-network-policy
spec:
  podSelector:
    matchLabels:
      app: web-app
  
  policyTypes:
  - Ingress
  - Egress
  
  # Ingress rules
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
    - podSelector:
        matchLabels:
          app: load-balancer
    ports:
    - protocol: TCP
      port: 8080
  
  # Egress rules
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
  - to: []  # Allow DNS
    ports:
    - protocol: UDP
      port: 53
```

### 3. **RBAC (Role-Based Access Control)**
Implementing fine-grained access control:

```yaml
# Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: production

---
# Role definition
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: app-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "update", "patch"]

---
# Role binding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: production
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

## 📊 Kubernetes Observability and Monitoring

### 1. **Metrics and Monitoring**
Comprehensive monitoring strategy:

```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: web-app-metrics
  labels:
    app: web-app
spec:
  selector:
    matchLabels:
      app: web-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /actuator/prometheus
    honorLabels: true

---
# Custom metrics configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
    - "/etc/prometheus/rules/*.yml"
    
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

### 2. **Logging Strategy**
Centralized logging implementation:

```yaml
# Fluentd DaemonSet for log collection
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

## 🚀 Advanced Kubernetes Patterns

### 1. **StatefulSets for Stateful Applications**
Managing stateful workloads:

```yaml
# StatefulSet for database cluster
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-cluster
spec:
  serviceName: postgres-headless
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: postgres
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "fast-ssd"
      resources:
        requests:
          storage: 100Gi
```

### 2. **Horizontal Pod Autoscaler (HPA)**
Automatic scaling based on metrics:

```yaml
# HPA with custom metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app-deployment
  minReplicas: 3
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1k"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

## 🎯 Production Readiness Checklist

### Infrastructure Requirements
- [ ] **High Availability**: Multi-AZ control plane deployment
- [ ] **Backup Strategy**: etcd backup and disaster recovery
- [ ] **Network Security**: Network policies and security groups
- [ ] **Resource Management**: Resource quotas and limits
- [ ] **Monitoring**: Comprehensive observability stack

### Security Hardening
- [ ] **RBAC**: Principle of least privilege access
- [ ] **Pod Security**: Security contexts and policies
- [ ] **Network Segmentation**: Network policies implementation
- [ ] **Secrets Management**: External secrets integration
- [ ] **Image Security**: Container image scanning

### Operational Excellence
- [ ] **GitOps**: Infrastructure and application deployment
- [ ] **CI/CD Integration**: Automated testing and deployment
- [ ] **Disaster Recovery**: Multi-region backup strategy
- [ ] **Cost Optimization**: Resource right-sizing and scheduling
- [ ] **Documentation**: Runbooks and operational procedures

---

**🎯 Master Kubernetes Architecture - Build Production-Ready Container Platforms!**
