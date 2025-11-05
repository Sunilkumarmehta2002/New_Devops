#!/bin/bash

set -e

echo "======================================"
echo "🚀 Starting Pro-vertos DevOps Automation"
echo "======================================"

# Check dependencies
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not installed."; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "❌ Ansible not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not installed or not integrated with WSL."; exit 1; }

# Export Mongo URI
if [ -z "$MONGO_URI" ]; then
  echo "❌ Please set MONGO_URI before running the script."
  echo "Example: export MONGO_URI='your-mongo-uri'"
  exit 1
fi

echo ""
echo "⚙️ Running Terraform..."
cd infra/terraform
terraform init -reconfigure
terraform apply -auto-approve -var="mongo_uri=$MONGO_URI"

cd ../ansible
echo ""
echo "🧩 Running Ansible playbook..."
ansible-playbook -i hosts.ini playbook.yml

echo ""
echo "🐳 Checking running containers..."
docker ps

echo ""
echo "======================================"
echo "✅ Setup Complete!"
echo "🌐 Frontend running on: http://localhost:3000"
echo "🔗 Backend running on:  http://localhost:5000"
echo "======================================"
