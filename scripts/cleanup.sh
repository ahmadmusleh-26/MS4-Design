#!/bin/bash
# Delete the GKE cluster (the only resource that costs money while idle).
#   bash scripts/cleanup.sh
source scripts/env.sh
gcloud container clusters delete $CLUSTER --zone $ZONE --quiet
gcloud container clusters list
