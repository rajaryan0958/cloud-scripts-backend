PROJECT_ID=$(gcloud config get-value project)

gcloud config set project "$PROJECT_ID"

read -p "Enter your Region (e.g., us-east1, us-west1, etc.): " REGION

gcloud config set compute/region "$REGION"

#read -p "Enter your Region (e.g., us-east1-a, us-west1-b, etc.): " ZONE

#gcloud config set compute/zone "$ZONE"

gcloud storage buckets create gs://$PROJECT_ID-tf-state --project=$PROJECT_ID --location=$REGION --uniform-bucket-level-access

gsutil versioning set on gs://$PROJECT_ID-tf-state

mkdir terraform-firewall && cd $_

cat > firewall.tf <<EOF
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-from-anywhere"
  network = "default"
  project = "$PROJECT_ID"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-allowed"]
}
EOF

cat > variables.tf <<EOF
variable "project_id" {
  type = string
  default = "$PROJECT_ID"
}

variable "bucket_name" {
  type = string
  default = "$PROJECT_ID-tf-state"
}

variable "region" {
  type = string
  default = "$REGION""
}
EOF

cat > outputs.tf <<EOF
output "firewall_name" {
  value = google_compute_firewall.allow_ssh.name
}
EOF

terraform init 

terraform plan

terraform apply -auto-approve
