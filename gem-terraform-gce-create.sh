PROJECT_ID=$(gcloud config get-value project)

gcloud config set project "$PROJECT_ID"

read -p "Enter your Region (e.g., us-east1, us-west1, etc.): " REGION
gcloud config set project "$REGION"

read -p "Enter your Region (e.g., us-east1, us-west1, etc.): " ZONE
gcloud config set project "ZONE"


gsutil mb -l $REGION gs://$PROJECT_ID-tf-state

gsutil versioning set on gs://$PROJECT_ID-tf-state

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

resource "google_compute_instance" "default" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = "default"

    access_config {
    }
  }
}
EOF

cat > variables.tf <<EOF
variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project"
  default = "$PROJECT_ID"
}

variable "region" {
  type        = string
  description = "The region to deploy resources in"
  default     = "$REGION"
}

variable "zone" {
  type        = string
  description = "The zone to deploy resources in"
  default     = "$ZONE"
}
EOF

terraform init

terraform plan

terraform apply -auto-approve

gcloud compute instances list

terraform destroy
