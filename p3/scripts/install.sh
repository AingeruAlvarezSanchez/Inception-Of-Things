#!/bin/sh
#
# sudo apt-get update
# sudo apt-get install -y docker.io
#
# sudo usermod -aG docker "$USER"
#
#curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

k3d cluster create inception

kubectl create namespace argocd
kubectl create namespace dev

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl get nodes,all,namespaces -o wide
