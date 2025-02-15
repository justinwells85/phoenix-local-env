#!/bin/bash

echo "⚠️ WARNING: This will completely reset the Phoenix environment!"
read -p "Are you sure? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "❌ Reset aborted."
    exit 1
fi

echo "🚨 Stopping and Removing Phoenix Environment..."

# Stop and remove all containers
docker-compose down -v

echo "🧹 Removing old Docker volumes..."
docker volume prune -f

echo "🔥 Rebuilding Phoenix Environment..."
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 10  # Adjust based on how long MySQL and LocalStack take to start

echo "✅ Verifying MySQL..."
docker exec -it firebird-aurora-mysql mysql -u phoenix_user --password=Pass123! --silent -e "SHOW DATABASES;"

echo "✅ Verifying LocalStack..."

# Ensure S3 bucket exists
aws --endpoint-url=http://localhost:4566 s3 mb s3://phoenix-bucket --profile localstack || true

# Ensure DynamoDB table exists
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
    --table-name phoenix-users \
    --attribute-definitions AttributeName=ID,AttributeType=S \
    --key-schema AttributeName=ID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --profile localstack || true

aws --endpoint-url=http://localhost:4566 dynamodb list-tables --profile localstack

echo "🚀 Phoenix environment is fully reset and operational!"


