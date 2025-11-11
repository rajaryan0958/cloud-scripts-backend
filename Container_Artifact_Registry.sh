gcloud services enable artifactregistry.googleapis.com

PROJECT_ID=$(gcloud config get-value project)

# Prompt user for Region
read -p "Enter your Region (e.g., us-east1, us-west1, etc.): " REGION

# Set gcloud configuration
gcloud config set project "$PROJECT_ID"
gcloud config set run/region "$REGION"


# Display what was set
echo "✅ Project ID automatically set to: $PROJECT_ID"
echo "✅ Cloud Run region automatically set to: $REGION"


gcloud artifacts repositories create my-docker-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository"

gcloud auth configure-docker $REGION-docker.pkg.dev

mkdir sample-app
cd sample-app
echo "FROM nginx:latest" > Dockerfile

docker build -t nginx-image .

docker tag nginx-image $REGION-docker.pkg.dev/$PROJECT_ID/my-docker-repo/nginx-image:latest

docker push $REGION-docker.pkg.dev/$PROJECT_ID/my-docker-repo/nginx-image:latest
