# Problem 30: Microservices Infrastructure with EKS

## Overview

This solution implements a complete production-ready EKS cluster with microservices infrastructure, including service mesh, monitoring, and sample applications.

## Architecture

- **EKS Cluster**: Managed Kubernetes cluster with node groups
- **Istio Service Mesh**: Complete service mesh with ingress/egress gateways
- **Monitoring Stack**: Prometheus, Grafana, and AlertManager
- **Sample Applications**: Microservices with auto-scaling and network policies

## Components

### Infrastructure
- VPC with public/private subnets across multiple AZs
- EKS cluster with managed node groups
- IAM roles and policies for cluster and nodes
- Security groups with proper ingress/egress rules

### Service Mesh
- Istio control plane installation via Helm
- Ingress and egress gateways
- Service mesh configuration for sample applications

### Monitoring
- Prometheus for metrics collection
- Grafana for visualization and dashboards
- AlertManager for alerting and notifications

### Applications
- Sample microservice deployment
- Kubernetes services and ingress
- Horizontal Pod Autoscaler (HPA)
- Network policies for security

## Usage

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

4. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

5. **Verify the deployment**:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

## Variables

- `cluster_name`: Name of the EKS cluster
- `aws_region`: AWS region for deployment
- `vpc_cidr`: CIDR block for the VPC
- `node_instance_types`: Instance types for worker nodes
- `node_desired_capacity`: Desired number of worker nodes

## Outputs

- `cluster_endpoint`: EKS cluster endpoint
- `cluster_security_group_id`: Cluster security group ID
- `cluster_iam_role_arn`: Cluster IAM role ARN
- `node_groups`: Information about node groups

## Security Features

- Network isolation with security groups
- IAM roles with least privilege access
- Encrypted EBS volumes for worker nodes
- Private subnets for worker nodes
- Network policies for pod-to-pod communication

## Monitoring and Observability

- Prometheus metrics collection
- Grafana dashboards for visualization
- AlertManager for notifications
- Service mesh observability with Istio

## Production Considerations

- Multi-AZ deployment for high availability
- Auto-scaling for worker nodes and applications
- Backup and disaster recovery strategies
- Security scanning and compliance
- Cost optimization with spot instances

## Troubleshooting

Common issues and solutions:

1. **Node group creation fails**: Check IAM permissions and subnet configuration
2. **Pods not scheduling**: Verify node capacity and resource requests
3. **Service mesh issues**: Check Istio installation and configuration
4. **Monitoring not working**: Verify Prometheus and Grafana deployments

## Next Steps

- Implement GitOps with ArgoCD or Flux
- Add more comprehensive monitoring and alerting
- Implement backup and disaster recovery
- Add security scanning and compliance checks
- Optimize costs with spot instances and cluster autoscaler
