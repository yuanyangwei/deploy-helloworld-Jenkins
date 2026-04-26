# Deploy Helloworld App with Jenkins, Docker, and Terraform

This project demonstrates a production-grade deployment of a simple Flask "Hello World" app to AWS ECS Fargate using Jenkins CI/CD and Terraform IaC.

## Project Structure

- `helloworld.py` — Flask app
- `dockerfile` — Docker build instructions
- `requirements.txt` — Python dependencies
- `Jenkinsfile` — Jenkins pipeline for CI/CD
- `terraform/` — Infrastructure as Code for AWS (ECS, ECR, VPC, etc.)

## Prerequisites

- AWS account with permissions for ECS, ECR, VPC, IAM
- Jenkins server with AWS CLI, Docker, Terraform, and required credentials configured
- Python 3.11+ (for local testing)

## Local Development

1. Install dependencies:
	```bash
	pip install -r requirements.txt
	```
2. Run the app:
	```bash
	python helloworld.py
	```
	Visit [http://localhost:5000/hello](http://localhost:5000/hello)

## Build & Push Docker Image

```bash
docker build -t helloworld:latest -f dockerfile .
```

## Infrastructure Deployment (Terraform)

1. Initialize Terraform:
	```bash
	cd terraform
	terraform init -backend-config="bucket=<state-bucket>" -backend-config="key=<project>/terraform.tfstate" -backend-config="region=<aws-region>"
	```
2. Plan and apply:
	```bash
	terraform plan -var='image_tag=latest' -var='aws_region=<region>' -var='project_name=<project>'
	terraform apply -auto-approve
	```

## CI/CD Pipeline (Jenkins)

The Jenkinsfile automates:
- Docker build & push to ECR
- Terraform plan & apply
- Deployment to AWS ECS Fargate

## Notes
- For production, use an Application Load Balancer and restrict public access.
- Add tests and health checks for robustness.
