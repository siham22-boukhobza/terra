# 🌐 Terraform AWS Infrastructure Project

This project provisions a full production-like AWS infrastructure using **Terraform** and follows best practices such as remote state management and infrastructure modularity.

---

## 🚀 What This Project Includes

- **VPC** with public and private subnets across two Availability Zones
- **Internet Gateway** for public internet access
- **NAT Gateway** to allow private instances to reach the internet
- **Security Groups** for ALB and EC2 with proper ingress/egress rules
- **Application Load Balancer (ALB)** to route traffic to EC2 instances
- **Launch Template** for EC2 instances (with user data)
- **Auto Scaling Group (ASG)** behind the ALB
- **Remote backend** in S3 with DynamoDB for state locking
- **Outputs** (e.g., ALB DNS) to easily access the deployed app

---

## 📦 Project Structure
