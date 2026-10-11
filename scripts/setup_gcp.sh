#!/bin/bash
# One-time setup of the GCP project for Milestone 4. Run from the repository root:
#   bash scripts/setup_gcp.sh
source scripts/env.sh

echo "== 1. Enable the APIs"
gcloud services enable container.googleapis.com artifactregistry.googleapis.com \
    pubsub.googleapis.com bigquery.googleapis.com

echo "== 2. Service account for the GKE nodes (no key is created)"
gcloud iam service-accounts create gke-ahmad --display-name "GKE nodes Ahmad" || true
sleep 10
for ROLE in roles/container.defaultNodeServiceAccount roles/artifactregistry.reader roles/pubsub.editor; do
    gcloud projects add-iam-policy-binding $PROJECT --member "serviceAccount:$GKE_SA" \
        --role $ROLE --condition None --format none
done

echo "== 3. Docker repository in Artifact Registry"
gcloud artifacts repositories create sofe4630u-ahmad --repository-format docker --location $REGION || true
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

echo "== 4. Pub/Sub topics"
gcloud pubsub topics create election-ahmad || true
gcloud pubsub topics create smartmeter-ahmad || true

echo "== 5. BigQuery table and BigQuery subscription (design part)"
bq --location $REGION mk --dataset $PROJECT:SmartMeter_ahmad || true
bq mk --table $PROJECT:SmartMeter_ahmad.Converted \
    time:FLOAT,profileName:STRING,temperature:FLOAT,humidity:FLOAT,pressure:FLOAT || true
gcloud beta services identity create --service pubsub.googleapis.com --project $PROJECT || true
gcloud projects add-iam-policy-binding $PROJECT \
    --member "serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
    --role roles/bigquery.dataEditor --condition None --format none
for i in 1 2 3 4 5 6; do
    gcloud pubsub subscriptions create smartmeter-ahmad-bq-sub --topic smartmeter-ahmad \
        --bigquery-table $PROJECT:SmartMeter_ahmad.Converted --use-table-schema --drop-unknown-fields \
        --message-filter 'attributes.function="converted reading"' && break
    echo "Waiting for the BigQuery permission to be applied..."; sleep 20
done

echo "== 6. Python library for the voting machine and the producer (Cloud Shell)"
pip install --quiet google-cloud-pubsub

echo "== 7. GKE cluster (2 small nodes). THIS COSTS MONEY UNTIL IT IS DELETED (scripts/cleanup.sh)"
gcloud container clusters create $CLUSTER --zone $ZONE \
    --num-nodes 2 --machine-type e2-medium --disk-type pd-standard --disk-size 30 \
    --service-account $GKE_SA --scopes cloud-platform
gcloud container clusters get-credentials $CLUSTER --zone $ZONE
kubectl get nodes
echo "== Setup done"
