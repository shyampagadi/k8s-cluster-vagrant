# Terraform Practice Problems: Zero to Hero in Kubernetes

## Table of Contents
1. [Foundation Level (Weeks 1-6)](#foundation-level-weeks-1-6---rock-solid-foundation)
2. [Intermediate Level (Weeks 7-8)](#intermediate-level-weeks-7-8---building-on-strong-foundation)
3. [Advanced Level (Weeks 9-10)](#advanced-level-weeks-9-10---advanced-concepts)
4. [Expert Level (Weeks 11-12)](#expert-level-weeks-11-12---expert-patterns)
5. [Production Scenarios (Weeks 13-14)](#production-scenarios-weeks-13-14---real-world-implementation)
6. [Kubernetes Mastery (Weeks 15-16)](#kubernetes-mastery-weeks-15-16---container-orchestration)
7. [Bonus Challenges](#bonus-challenges)

---

## Kubernetes Mastery (Weeks 15-16) - CONTAINER ORCHESTRATION

### Problem 35: Kubernetes Fundamentals with Terraform
**Difficulty**: Intermediate to Advanced  
**Estimated Time**: 180 minutes  
**Learning Objectives**: Kubernetes resources, ConfigMaps, Secrets, Deployments, Services, Ingress

**Scenario**: 
Your organization has successfully deployed an EKS cluster and now needs to deploy and manage Kubernetes applications using Terraform. As the platform engineer, you need to demonstrate how to manage Kubernetes resources declaratively using Terraform, including application deployments, configuration management, storage, networking, and monitoring integration. This problem focuses on the practical aspects of managing Kubernetes workloads through Infrastructure as Code, ensuring that applications are properly configured, secured, and scalable.

**Requirements**:

1. **Deploy Kubernetes Namespaces and RBAC**
   - Create dedicated namespaces for different environments
   - Implement proper resource quotas and limits
   - Set up service accounts with appropriate permissions
   - Configure network policies for security isolation

2. **Implement Configuration Management**
   - Create ConfigMaps for application configuration
   - Manage Secrets for sensitive data (database credentials, API keys)
   - Demonstrate configuration injection into pods
   - Implement configuration versioning and rollback strategies

3. **Deploy Stateless Applications**
   - Create Deployment resources with proper resource limits
   - Implement health checks (liveness and readiness probes)
   - Configure horizontal pod autoscaling
   - Set up rolling update strategies

4. **Deploy Stateful Applications**
   - Create StatefulSet for database workloads
   - Implement persistent volume claims
   - Configure headless services for StatefulSets
   - Set up database initialization jobs

5. **Implement Service Discovery and Load Balancing**
   - Create ClusterIP services for internal communication
   - Set up LoadBalancer services for external access
   - Configure Ingress resources with path-based routing
   - Implement service mesh integration (Istio)

6. **Set up Storage Management**
   - Configure persistent volumes and claims
   - Implement storage classes for different performance tiers
   - Set up backup and restore procedures
   - Configure volume snapshots

7. **Implement Monitoring and Observability**
   - Deploy Prometheus ServiceMonitors
   - Configure Grafana dashboards
   - Set up log aggregation with Fluentd
   - Implement distributed tracing

8. **Configure Batch Jobs and CronJobs**
   - Create one-time initialization jobs
   - Set up recurring maintenance tasks
   - Implement job cleanup policies
   - Configure job monitoring and alerting

**Expected Deliverables**:

1. **Complete Kubernetes Application Stack**
   - Terraform configuration managing all Kubernetes resources
   - Proper separation of concerns with modules
   - Environment-specific configurations
   - Comprehensive resource tagging and labeling

2. **Security Implementation**
   - Network policies restricting pod-to-pod communication
   - Pod security standards enforcement
   - Secret management with encryption at rest
   - RBAC policies with least privilege access

3. **Monitoring and Observability Setup**
   - Prometheus metrics collection
   - Grafana visualization dashboards
   - Log aggregation and analysis
   - Alerting rules and notification channels

4. **Documentation and Runbooks**
   - Deployment procedures and troubleshooting guides
   - Scaling and maintenance procedures
   - Disaster recovery and backup strategies
   - Performance tuning recommendations

**Knowledge Check**:
- How do you manage Kubernetes resources declaratively with Terraform?
- What are the best practices for ConfigMap and Secret management?
- How do you implement proper resource limits and quotas?
- What are the differences between Deployments and StatefulSets?
- How do you configure ingress controllers and load balancing?
- What are the security considerations for Kubernetes deployments?

---

### Problem 36: Advanced EKS with Service Mesh
**Difficulty**: Expert  
**Estimated Time**: 240 minutes  
**Learning Objectives**: EKS cluster management, Istio service mesh, advanced networking, security

**Scenario**: 
Your organization is building a microservices platform that requires advanced traffic management, security policies, and observability. You need to deploy a production-ready EKS cluster with Istio service mesh, implement advanced networking patterns, and ensure comprehensive security and monitoring. This represents the culmination of Kubernetes and Terraform knowledge, combining infrastructure provisioning with advanced container orchestration patterns.

**Requirements**:

1. **Deploy Production-Ready EKS Cluster**
   - Multi-AZ cluster with managed node groups
   - Spot and on-demand instance mix for cost optimization
   - Cluster autoscaling and node group scaling policies
   - Advanced networking with custom CNI configuration

2. **Implement Istio Service Mesh**
   - Complete Istio installation with all components
   - Configure ingress and egress gateways
   - Implement traffic management policies
   - Set up mutual TLS for service-to-service communication

3. **Advanced Traffic Management**
   - Implement canary deployments with traffic splitting
   - Configure circuit breakers and retry policies
   - Set up rate limiting and throttling
   - Implement blue-green deployment strategies

4. **Comprehensive Security Implementation**
   - Pod Security Standards enforcement
   - Network policies with deny-by-default approach
   - Workload identity and service account management
   - Secrets management with external secret operators

5. **Monitoring and Observability Stack**
   - Prometheus and Grafana with custom dashboards
   - Jaeger for distributed tracing
   - ELK stack for log aggregation
   - Custom metrics and alerting rules

6. **Multi-Environment Management**
   - Separate clusters for dev, staging, and production
   - GitOps workflow with ArgoCD
   - Environment-specific configurations
   - Promotion pipelines between environments

**Expected Deliverables**:

1. **Complete EKS Infrastructure**
   - Production-ready cluster configuration
   - Advanced networking and security setup
   - Cost-optimized node group configurations
   - Comprehensive monitoring and logging

2. **Service Mesh Implementation**
   - Istio configuration with all features
   - Traffic management and security policies
   - Observability and tracing setup
   - Performance optimization configurations

3. **CI/CD Integration**
   - GitOps workflow implementation
   - Automated testing and deployment pipelines
   - Environment promotion strategies
   - Rollback and disaster recovery procedures

**Knowledge Check**:
- How do you design and implement a production-ready EKS cluster?
- What are the key components and benefits of a service mesh?
- How do you implement advanced traffic management patterns?
- What are the security best practices for Kubernetes in production?
- How do you set up comprehensive monitoring and observability?
- What are the considerations for multi-environment Kubernetes management?

---

## Updated Learning Path Recommendations

### Week-by-Week Schedule:
- **Weeks 1-6**: Foundation Level (Problems 1-20) - ROCK-SOLID FOUNDATION
- **Weeks 7-8**: Intermediate Level (Problems 21-23) - BUILDING ON STRONG FOUNDATION  
- **Weeks 9-10**: Advanced Level (Problems 24-26) - ADVANCED CONCEPTS
- **Weeks 11-12**: Expert Level (Problems 27-29) - EXPERT PATTERNS
- **Weeks 13-14**: Production Scenarios (Problems 30-32) - REAL-WORLD IMPLEMENTATION
- **Weeks 15-16**: Kubernetes Mastery (Problems 35-36) - CONTAINER ORCHESTRATION
- **Weeks 17-18**: Bonus Challenges (Problems 33-34) - ADVANCED PATTERNS

### Kubernetes Learning Prerequisites:
Before starting the Kubernetes Mastery section, ensure you have:
- Completed all Foundation and Intermediate problems
- Basic understanding of containerization (Docker)
- Familiarity with YAML syntax and Kubernetes concepts
- AWS CLI and kubectl installed and configured

### Estimated Total Learning Time:
- **Foundation Level**: 60-80 hours (6 weeks × 10-13 hours/week)
- **Intermediate Level**: 20-30 hours (2 weeks × 10-15 hours/week)
- **Advanced Level**: 30-40 hours (2 weeks × 15-20 hours/week)
- **Expert Level**: 40-50 hours (2 weeks × 20-25 hours/week)
- **Production Scenarios**: 50-60 hours (2 weeks × 25-30 hours/week)
- **Kubernetes Mastery**: 40-50 hours (2 weeks × 20-25 hours/week)
- **Bonus Challenges**: 20-30 hours (2 weeks × 10-15 hours/week)
- **Total**: 260-340 hours over 18 weeks

---

## Success Metrics

### Foundation Mastery:
- Can create and manage basic AWS resources with Terraform
- Understands Terraform state management and workflows
- Can implement variables, outputs, and basic functions

### Intermediate Mastery:
- Can create reusable Terraform modules
- Understands advanced Terraform patterns and best practices
- Can implement complex infrastructure scenarios

### Advanced Mastery:
- Can design enterprise-grade infrastructure solutions
- Understands security, compliance, and governance patterns
- Can implement CI/CD integration and automation

### Expert Mastery:
- Can architect multi-cloud and hybrid solutions
- Understands advanced patterns like policy as code
- Can mentor others and lead infrastructure initiatives

### Kubernetes Mastery:
- Can deploy and manage production Kubernetes workloads
- Understands service mesh and advanced networking patterns
- Can implement comprehensive monitoring and security
- Can design and operate microservices platforms

### Production Readiness:
- Can deploy and maintain production infrastructure
- Understands disaster recovery and business continuity
- Can optimize costs and performance at scale
- Can implement comprehensive security and compliance

This updated curriculum now provides a complete path from Terraform basics to advanced Kubernetes orchestration, fulfilling the promise of "zero to hero in Kubernetes" while maintaining the high-quality standards established in the foundation problems.
