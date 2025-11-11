PROJECT_ID=$(gcloud config get-value project)

gcloud config set project "$PROJECT_ID"

read -p "Enter your Region (e.g., us-east1, us-west1, etc.): " REGION

gcloud config set compute/region "$REGION"

gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com

gcloud artifacts repositories create caddy-repo --repository-format=docker --location=$REGION --description="Docker repository for Caddy images"

cat > index.html <<EOF
<html>
<head>
  <title>My Static Website</title>
</head>
<body>
  <div>Hello from Caddy on Cloud Run!</div>
  <p>This website is served by Caddy running in a Docker container on Google Cloud Run.</p>
</body>
</html>
EOF

cat > Caddyfile <<EOF
:8080
root * /usr/share/caddy
file_server
EOF

cat > Dockerfile <<EOF
FROM caddy:2-alpine

WORKDIR /usr/share/caddy

COPY index.html .
COPY Caddyfile /etc/caddy/Caddyfile
EOF

docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/caddy-repo/caddy-static:latest .

docker push $REGION-docker.pkg.dev/$PROJECT_ID/caddy-repo/caddy-static:latest

gcloud run deploy caddy-static --image $REGION-docker.pkg.dev/$PROJECT_ID/caddy-repo/caddy-static:latest --platform managed --allow-unauthenticated

echo "✅ OPEN THE ABOVE LINK TO GET FULL SCORE"
