# 🔐 Secure AWS API Platform

> **Production-ready serverless API architecture** leveraging AWS native services with a **Zero-Trust security model**, Infrastructure-as-Code (Terraform), and **end-to-end encryption**.

![AWS](https://img.shields.io/badge/AWS-Serverless-FF9900?logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![Architecture](https://img.shields.io/badge/Security-Zero%20Trust-green)

## ⚡ Key Features

- **Fully Serverless**: Auto-scales from zero to millions of requests with **zero idle costs**
- **Zero-Trust Security**: Identity-based access control at every layer
- **Production-Ready**: Automated state management, encryption at rest & in transit
- **Infrastructure as Code**: Complete AWS stack managed via Terraform
- **Enterprise Logging**: Centralized monitoring with CloudWatch integration
- **Modular Design**: Separate Terraform modules for maintainability

---

## 🏗️ Architecture Overview

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ├─── [1] Authenticate ──────────────┐
       │                                    │
       ├─── [2] JWT Token ──────┐          │
       │                        ▼          ▼
       │                   ┌─────────────────────────┐
       │                   │  AWS Cognito User Pool  │ ◄─── Authentication & Tokens
       │                   └─────────────────────────┘
       │                        │
       └────► AWS API Gateway ◄─┘  Token Validation
              (REST API)
                    │
                    ├─► CloudWatch (Logging & Monitoring)
                    │
                    ▼
              AWS Lambda Execution
              (IAM-based authorization)
                    │
                    ▼
              Amazon DynamoDB
              (Data Storage & Access)
```

### Security Layers
1. **Authentication Layer**: AWS Cognito JWT-based user authentication
2. **Authorization Layer**: IAM execution roles for Lambda
3. **Data Layer**: Identity-based access control on DynamoDB
4. **Monitoring**: CloudWatch for audit logs and threat detection

---

## 📦 Technology Stack

| Layer | Technology |
|-------|-----------|
| **IaC** | Terraform `~> 1.5.0` |
| **Authentication** | AWS Cognito (User Pools) |
| **API** | AWS API Gateway (REST) |
| **Compute** | AWS Lambda (Node.js) |
| **Database** | Amazon DynamoDB |
| **Monitoring** | AWS CloudWatch |
| **State Management** | S3 + DynamoDB Locking |
| **Region** | eu-north-1 (Stockholm) |

---

## 🚀 Quick Start

### Prerequisites
```bash
terraform >= 1.5.0
aws-cli >= 2.0
AWS Account with appropriate permissions
```

### Deploy
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy to AWS
terraform apply
```

### Access
After deployment, get your API endpoint:
```bash
terraform output api_endpoint
terraform output cognito_user_pool_id
terraform output cognito_client_id
```

---

## 📁 Project Structure

```
secure-aws-platform/
├── main.tf                 # Main configuration & module orchestration
├── variables.tf            # Input variables (AWS region, etc.)
├── outputs.tf              # Output values (API endpoint, auth credentials)
├── modules/
│   ├── database/          # DynamoDB setup with identity-based access
│   ├── lambda/            # Lambda function with IAM execution role
│   ├── cognito/           # User authentication & JWT token generation
│   └── api_gateway/       # REST API with authorization
└── terraform.tfstate      # State file (S3 backend with encryption)
```

### Module Breakdown

**database/** → DynamoDB tables with fine-grained IAM policies
**lambda/** → Lambda function with environment variables & execution role
**cognito/** → User pool, app client, and token configuration  
**api_gateway/** → REST endpoints with Cognito authorization

---

## 🔒 Security Highlights

✅ **Zero-Trust by Design**
- Every request requires valid JWT token
- Lambda execution limited via IAM roles
- DynamoDB access restricted by resource policy

✅ **Encryption**
- Terraform state encrypted in S3
- DynamoDB point-in-time recovery
- CloudWatch logs with retention policies

✅ **Compliance Ready**
- Audit trails via CloudWatch
- Resource tagging for cost allocation
- Automatic backups and disaster recovery

---

## 📊 Cost Optimization

- **Pay per invocation**: Lambda only charges for execution time
- **On-demand DynamoDB**: Scales automatically without pre-provisioning
- **Zero idle costs**: No resources running when not in use
- **Free tier eligible**: Suitable for development and testing

**Typical production costs**: $0-50/month depending on traffic

---

## 🛠️ Development Workflow

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan -out=tfplan

# Apply with review
terraform apply tfplan

# Destroy environment
terraform destroy
```

---

## 📈 Monitoring & Logs

All Lambda executions and API calls are logged to CloudWatch:

```bash
# View Lambda logs
aws logs tail /aws/lambda/secure-api-function --follow

# View API Gateway logs
aws logs tail /aws/apigateway/secure-api --follow
```

---

## 🎯 Use Cases

- 🌐 REST APIs with user authentication
- 📱 Mobile app backends
- 🔐 Microservices with identity-based access
- 📊 Event-driven data processing
- 🤖 Webhook handlers and integrations

---

## 📚 Learning & Skills Demonstrated

### Core Cloud Architecture
- Serverless application design patterns
- Zero-Trust security model implementation
- Event-driven architecture on AWS

### Infrastructure as Code
- Terraform modular design and composition
- State management and locking strategies
- Resource lifecycle management

### AWS Services
- Cognito authentication flows
- Lambda execution roles and permissions
- DynamoDB access patterns
- API Gateway authorization
- CloudWatch observability

### DevOps & Best Practices
- Infrastructure versioning
- Automated deployments
- Cost optimization
- Security hardening
- Scalability patterns

---

## 🤝 Contributing

This is a production-grade reference implementation. Feel free to fork, modify, and adapt to your use case.

## 📄 License

[Choose your license - MIT/Apache 2.0/etc.]

---

**Created**: 2024 | **Region**: eu-north-1 | **Status**: Production-Ready ✅