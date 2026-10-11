#!/bin/bash
# Build the voting system images, push them to Artifact Registry, and deploy them on GKE.
#   bash scripts/deploy_voting.sh
source scripts/env.sh
set -e

echo "== Logger service image"
docker build voting_system/voting_logger -t $LOGGER_IMAGE
docker push $LOGGER_IMAGE

echo "== Recorder service image"
docker build voting_system/voting_record -t $RECORDER_IMAGE
docker push $RECORDER_IMAGE

echo "== PostgreSQL image (creates the votes table)"
docker build voting_system/voting_record/postgres -t $POSTGRES_IMAGE
docker push $POSTGRES_IMAGE

echo "== Deploy the logger service and Redis"
PROJECT=$PROJECT LOGGER_IMAGE=$LOGGER_IMAGE envsubst < voting_system/voting_logger/logger.yaml | kubectl apply -f -

echo "== Deploy the recorder service and PostgreSQL"
POSTGRES_IMAGE=$POSTGRES_IMAGE PROJECT=$PROJECT RECORDER_IMAGE=$RECORDER_IMAGE \
    envsubst < voting_system/voting_record/recorder.yaml | kubectl apply -f -

kubectl get pods
