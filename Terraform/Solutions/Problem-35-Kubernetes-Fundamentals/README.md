# Problem 35: Kubernetes Fundamentals with Terraform

## Overview

This solution demonstrates comprehensive Kubernetes resource management using Terraform, covering all fundamental Kubernetes objects and advanced patterns.

## Architecture

This implementation creates a complete microservices application stack with:

- **Multi-tier Application**: Web frontend, API backend, and database
- **Service Discovery**: Kubernetes services for internal communication
- **Configuration Management**: ConfigMaps and Secrets
- **Storage**: Persistent volumes and claims
- **Networking**: Ingress controllers and network policies
- **Scaling**: Horizontal Pod Autoscalers
- **Jobs**: One-time and scheduled tasks
- **Security**: RBAC with service accounts, roles, and bindings

## Components

### Core Resources
- **Namespace**: Isolated environment for applications
- **Deployments**: Stateless application workloads
- **StatefulSets**: Stateful applications like databases
- **Services**: Service discovery and load balancing
- **Ingress**: External access to services

### Configuration and Secrets
- **ConfigMaps**: Application configuration data
- **Secrets**: Sensitive data like passwords and API keys

### Storage
- **Persistent Volumes**: Cluster-wide storage resources
- **Persistent Volume Claims**: Storage requests by pods

### Networking
- **Network Policies**: Pod-to-pod communication rules
- **Ingress Controllers**: HTTP/HTTPS routing

### Scaling and Jobs
- **Horizontal Pod Autoscaler**: Automatic scaling based on metrics
- **Jobs**: One-time task execution
- **CronJobs**: Scheduled task execution

### Security
- **Service Accounts**: Pod identity
- **Roles**: Permission definitions
- **Role Bindings**: Permission assignments

## Prerequisites

- Existing EKS cluster (can use Problem 30 solution)
- kubectl configured to access the cluster
- Terraform with Kubernetes provider

## Usage

1. **Set cluster name**:
   ```bash
   export TF_VAR_cluster_name="your-eks-cluster-name"
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan the deployment**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

5. **Verify the deployment**:
   ```bash
   kubectl get all -n microservices
   kubectl get pv,pvc -n microservices
   kubectl get networkpolicies -n microservices
   ```

## Variables

- `cluster_name`: Name of the existing EKS cluster
- `aws_region`: AWS region where the cluster is located
- `namespace_name`: Kubernetes namespace for resources
- `app_version`: Version tag for application images
- `replica_count`: Number of replicas for each deployment

## Outputs

- Service names and cluster IPs
- Ingress configuration
- ConfigMap and Secret names
- Persistent volume information
- HPA and job names

## Application Stack

### Web Application (Frontend)
- **Deployment**: 3 replicas with nginx
- **Service**: ClusterIP for internal access
- **Ingress**: External HTTP/HTTPS access
- **HPA**: Scales 2-10 replicas based on CPU/memory

### API Application (Backend)
- **Deployment**: 3 replicas with API server
- **Service**: ClusterIP for internal access
- **ConfigMap**: Application configuration
- **Secret**: API keys and database credentials
- **HPA**: Scales 2-8 replicas based on CPU/memory

### Database (Stateful)
- **StatefulSet**: Single replica PostgreSQL
- **Service**: Headless service for stable network identity
- **Persistent Volume**: 20Gi storage for data
- **Secret**: Database credentials

### Jobs and Automation
- **Job**: Database migration on deployment
- **CronJob**: Daily backup at 2 AM
- **Service Account**: Permissions for job execution

## Security Features

### Network Policies
- Deny all ingress traffic by default
- Allow specific communication between tiers
- Allow egress to external services

### RBAC
- Service account for applications
- Role with minimal required permissions
- Role binding to associate account with role

### Secrets Management
- Database credentials stored as secrets
- API keys and tokens encrypted
- Mounted as environment variables or files

## Monitoring and Observability

### Resource Monitoring
- CPU and memory requests/limits
- HPA metrics collection
- Persistent volume usage

### Health Checks
- Liveness probes for application health
- Readiness probes for traffic routing
- Startup probes for slow-starting containers

## Best Practices Implemented

1. **Resource Management**
   - CPU and memory requests/limits
   - Quality of Service classes
   - Resource quotas and limits

2. **Security**
   - Non-root containers
   - Read-only root filesystems
   - Security contexts and policies

3. **High Availability**
   - Multiple replicas
   - Pod disruption budgets
   - Anti-affinity rules

4. **Configuration**
   - Externalized configuration
   - Environment-specific values
   - Secret management

## Troubleshooting

Common issues and solutions:

1. **Pods not starting**: Check resource requests and node capacity
2. **Services not accessible**: Verify service selectors and endpoints
3. **Persistent volumes not mounting**: Check storage class and permissions
4. **Network policies blocking traffic**: Review policy rules and labels
5. **HPA not scaling**: Verify metrics server and resource requests

## Advanced Patterns

### Blue-Green Deployments
- Multiple service versions
- Traffic switching strategies
- Rollback procedures

### Canary Deployments
- Gradual traffic shifting
- A/B testing capabilities
- Automated rollback triggers

### Multi-Environment Management
- Environment-specific configurations
- Namespace isolation
- Resource quotas per environment

## Integration with AWS Services

- **EBS**: Persistent volume storage
- **ALB**: Ingress controller integration
- **IAM**: Service account roles (IRSA)
- **CloudWatch**: Metrics and logging
- **Secrets Manager**: External secret management

## Next Steps

- Implement GitOps with ArgoCD or Flux
- Add comprehensive monitoring with Prometheus
- Implement service mesh with Istio
- Add security scanning and policy enforcement
- Implement backup and disaster recovery strategies
