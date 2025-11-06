#!/bin/bash

# ================================
# 🚀 Pro-vertos DevOps Automation Script
# Author: Sunil Kumar Mehta
# ================================

set -e  # Exit on error

# --- Color Codes ---
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[36m"
RESET="\e[0m"

echo -e "${BLUE}======================================"
echo -e "🚀 Starting Pro-vertos DevOps Automation"
echo -e "======================================${RESET}"

# --- Helper Function ---
check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${YELLOW}⚠️ $1 not found. Installing...${RESET}"
    case "$1" in
    terraform)
      sudo apt-get update -y && sudo apt-get install -y wget unzip
      wget -O terraform.zip https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
      unzip terraform.zip && sudo mv terraform /usr/local/bin/ && rm terraform.zip
      ;;
    ansible)
      sudo apt-get update -y && sudo apt-get install -y ansible
      ;;
    docker)
      echo -e "${YELLOW}⚠️ Installing Docker...${RESET}"
      sudo apt-get update -y
      sudo apt-get install -y ca-certificates curl gnupg lsb-release
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      sudo apt-get update -y
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
      ;;
    *)
      echo -e "${RED}❌ Unknown dependency: $1${RESET}"
      exit 1
      ;;
    esac
  else
    echo -e "${GREEN}✅ $1 is installed.${RESET}"
  fi
}

# --- Check Required Tools ---
check_command terraform
check_command ansible
check_command docker

# --- Docker WSL Integration Check ---
if ! docker info &>/dev/null; then
  echo -e "${RED}❌ Docker is not running or not integrated with WSL2.${RESET}"
  echo -e "${YELLOW}👉 Open Docker Desktop > Settings > Resources > WSL Integration${RESET}"
  echo -e "${YELLOW}   Enable Ubuntu integration, then restart Docker Desktop.${RESET}"
  exit 1
fi

# --- Mongo URI Check ---
if [ -z "$MONGO_URL" ]; then
  echo -e "${YELLOW}⚠️ Mongo URI not found. Please enter your MongoDB URL below:${RESET}"
  read -r -p "🔗 Enter MongoDB URI: " MONGO_URL
  export MONGO_URL
fi

echo -e "${GREEN}✅ Mongo URI configured successfully.${RESET}"

# --- Stop Old Containers (if exist) ---
echo -e "\n${BLUE}🧹 Cleaning old containers (if any)...${RESET}"
docker ps -q --filter "name=pro_" | xargs -r docker stop
docker ps -a -q --filter "name=pro_" | xargs -r docker rm

# --- Terraform Phase ---
echo -e "\n${BLUE}⚙️ Running Terraform...${RESET}"
cd infra/terraform || { echo "❌ Missing infra/terraform directory"; exit 1; }

# Clean any old state
rm -f .terraform.lock.hcl

terraform init -reconfigure
terraform apply -auto-approve -var="mongo_url=$MONGO_URL" -var="dockerhub_username=sunilkumarmehta2002"
terraform apply -auto-approve -parallelism=2


cd ../../

# --- Ansible Phase ---
echo -e "\n${BLUE}🧩 Running Ansible Playbook...${RESET}"
cd infra/ansible || { echo "❌ Missing infra/ansible directory"; exit 1; }

ansible-playbook -i hosts.ini playbook.yml -v

cd ../../

# --- Docker Status ---
echo -e "\n${BLUE}🐳 Checking Docker Containers...${RESET}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${GREEN}======================================"
echo -e "✅ Setup Complete!"
echo -e "🌐 Frontend running on: ${YELLOW}http://localhost:3000${RESET}"
echo -e "🔗 Backend running on:  ${YELLOW}http://localhost:5000${RESET}"
echo -e "======================================${RESET}"
