#!/bin/bash
#
# sudo apt-get update
# sudo apt-get install -y docker.io
#
# sudo usermod -aG docker "$USER"
#
#curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
set -euo pipefail

k3d cluster delete inception
k3d cluster create inception

kubectl create namespace dev
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

git clone https://github.com/dugonzal/dugonzal_ci_di.git /tmp/inception

kubectl apply -n argocd -f /tmp/inception/manifest/application.yaml

sudo rm -rf /tmp/inception

kubectl wait \
  --for=condition=available \
  deployment/argocd-server \
  -n argocd \
  --timeout=2m

kubectl -n argocd port-forward svc/argocd-server 8080:443 &

kubectl -n dev port-forward services/svc-wil42 8888:8888 &

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" |
  base64 -d
echo
