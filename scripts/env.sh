# Shared variables. Load them with:  source scripts/env.sh
PROJECT=$(gcloud config list project --format "value(core.project)")
PROJECT_NUMBER=$(gcloud projects describe $PROJECT --format "value(projectNumber)")
REGION=northamerica-northeast2
ZONE=northamerica-northeast2-a
REPO=$REGION-docker.pkg.dev/$PROJECT/sofe4630u-ahmad
CLUSTER=ahmad-cluster
GKE_SA=gke-ahmad@$PROJECT.iam.gserviceaccount.com

LOGGER_IMAGE=$REPO/logger
RECORDER_IMAGE=$REPO/recorder
POSTGRES_IMAGE=$REPO/postgres:election
FILTER_IMAGE=$REPO/filter-reading
CONVERT_IMAGE=$REPO/convert-reading

echo "PROJECT=$PROJECT"
echo "REPO=$REPO"
