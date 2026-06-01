# Secure AWS API Platform (Infrastructure as Code)

A cloud-native, production-ready serverless API platform deployed on AWS using Terraform. This architecture implements a **Zero-Trust** security model at the API edge, leveraging AWS native capabilities to minimize operations, maintenance overhead, and vulnerability footprints.

## 🏗️ Architecture Overview

The platform uses a fully serverless, event-driven design pattern to scale seamlessly from zero to millions of requests while keeping idle costs at exactly $0.00.

```mermaid
graph TD
    User([Client / Frontend]) -->|1. Authenticate| Cognito[AWS Cognito User Pool]
    User -->|2. Secure Request + JWT Token| API_GW[AWS API Gateway - REST API]
    Cognito -.-->|3. Token Verification| API_GW
    API_GW -->|4. IAM Execution Role| Lambda[AWS Lambda - Backend]
    Lambda -->|5. Identity-Based Access| DynamoDB[(Amazon DynamoDB)]
    
    API_GW -->|Logs| CloudWatch[AWS CloudWatch]
    Lambda -->|Logs| CloudWatch