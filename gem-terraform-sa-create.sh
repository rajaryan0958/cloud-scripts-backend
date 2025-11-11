PROJECT_ID=$(gcloud config get-value project)

gcloud config set project "$PROJECT_ID"

read -p "Enter your Region (e.g., us-east1, us-west1, etc.): " REGION

gcloud config set compute/region "$REGION"

#read -p "Enter your Region (e.g., us-east1-a, us-west1-b, etc.): " ZONE

#gcloud config set compute/zone "$ZONE"

gcloud services enable iam.googleapis.com

gcloud storage buckets create gs://$PROJECT_ID-tf-state --project=$PROJECT_ID --location=$REGION --uniform-bucket-level-access

gsutil versioning set on gs://$PROJECT_ID-tf-state

mkdir terraform-service-account && cd $_

cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "$PROJECT_ID-tf-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region 
}

resource "google_service_account" "default" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}
EOF

cat > variables.tf <<EOF
variable "project_id" {
  type = string
  description = "The GCP project ID"
  default = "$PROJECT_ID"
}

variable "region" {
  type = string
  description = "The GCP region"
  default = "$REGION"
}
EOF

terraform init

terraform apply -auto-approve

gcloud iam service-accounts list --project=$PROJECT_ID
