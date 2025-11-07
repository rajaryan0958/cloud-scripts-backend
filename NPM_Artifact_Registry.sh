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

gcloud artifacts repositories create my-npm-repo \
    --repository-format=npm \
    --location="$REGION" \
    --description="NPM repository"

mkdir my-npm-package
cd my-npm-package

npm init --scope=@"$PROJECT_ID" -y

echo 'console.log(`Hello from my-npm-package!`);' > index.js

gcloud artifacts print-settings npm \
    --project="$PROJECT_ID" \
    --repository=my-npm-repo \
    --location="$REGION" \
    --scope=@"PROJECT_ID" > ./.npmrc

gcloud auth configure-docker "$REGION"-npm.pkg.dev

cat > package.json <<EOF
{
  "name": "@qwiklabs-gcp-00-e9159952f381/my-npm-package",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "artifactregistry-login": "npx google-artifactregistry-auth --repo-config=./.npmrc --credential-config=./.npmrc",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "type": "commonjs"
}
EOF

npm run artifactregistry-login

cat .npmrc

npm publish --registry=https://"$REGION"-npm.pkg.dev/"$PROJECT_ID"/my-npm-repo/

gcloud artifacts packages list --repository=my-npm-repo --location="$REGION"
