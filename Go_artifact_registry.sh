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

gcloud artifacts repositories create my-go-repo \
    --repository-format=go \
    --location=$REGION \
    --description="Go repository"

gcloud artifacts repositories describe my-go-repo \
    --location=$REGION

go env -w GOPRIVATE=cloud.google.com/$PROJECT_ID

export GONOPROXY=github.com/GoogleCloudPlatform/artifact-registry-go-tools
GOPROXY=proxy.golang.org go run github.com/GoogleCloudPlatform/artifact-registry-go-tools/cmd/auth@latest add-locations --locations=$REGION

mkdir hello
cd hello

go mod init labdemo.app/hello

cat > hello.go <<EOF
package main

import "fmt"

func main() {
	fmt.Println("Hello, Go module from Artifact Registry!")
}
EOF

go build

read -p "Enter Email: " EMAIL

git config --global user.email "$EMAIL"

git config --global user.name cls 

git config --global init.defaultBranch main 

git init

git add .

git commit -m "Initial commit"

git tag v1.0.0

gcloud artifacts go upload \
  --repository=my-go-repo \
  --location=$REGION \
  --module-path=labdemo.app/hello \
  --version=v1.0.0 \
  --source=.

gcloud artifacts packages list --repository=my-go-repo --location=$REGION

