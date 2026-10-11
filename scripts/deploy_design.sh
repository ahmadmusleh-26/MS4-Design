#!/bin/bash
# Build the FilterReading and ConvertReading images, push them, and deploy them on GKE.
#   bash scripts/deploy_design.sh
source scripts/env.sh
set -e

echo "== FilterReading image"
docker build filter_reading -t $FILTER_IMAGE
docker push $FILTER_IMAGE

echo "== ConvertReading image"
docker build convert_reading -t $CONVERT_IMAGE
docker push $CONVERT_IMAGE

echo "== Deploy the two microservices"
PROJECT=$PROJECT FILTER_IMAGE=$FILTER_IMAGE CONVERT_IMAGE=$CONVERT_IMAGE envsubst < design.yaml | kubectl apply -f -

kubectl get pods
