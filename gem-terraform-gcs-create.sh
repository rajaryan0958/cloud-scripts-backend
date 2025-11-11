PROJECT_ID=$(gcloud config get-value project)

gcloud config set project "$PROJECT_ID"

read -p "Enter your Region (e.g., us-east1, us-west1, etc.): " REGION

gcloud config set compute/region "$REGION"

#read -p "Enter your Region (e.g., us-east1-a, us-west1-b, etc.): " ZONE

#gcloud config set compute/zone "$ZONE"

gcloud storage buckets create gs://$PROJECT_ID-tf-state --project=$PROJECT_ID --location=$REGION --uniform-bucket-level-access

gsutil versioning set on gs://$PROJECT_ID-tf-state

mkdir terraform-gcs && cd $_

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
  project = "$PROJECT_ID"
  region  = "$REGION"
}

resource "google_storage_bucket" "default" {
  name          = "$PROJECT_ID-my-terraform-bucket"
  location      = "$REGION"
  force_destroy = true

  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}
EOF

terraform init

terraform plan

terraform apply -auto-approve
