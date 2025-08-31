k3d cluster delete inception

k3d cluster create inception \
  --k3s-arg "--disable=traefik@server:0" \
  -p "80:80@loadbalancer" \
  -p "22:22@loadbalancer" \
  -p "443:443@loadbalancer"

helm upgrade --install traefik-crds traefik/traefik-crds --namespace kube-system --create-namespace

kubectl create namespace gitlab || true

mkdir -p certs

sleep 5
#
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#   -keyout certs/gitlab.example.com-key.pem \
#   -out certs/gitlab.example.com.pem \
#   -subj "/CN=gitlab.example.com/O=MyOrg"
#
kubectl create secret tls gitlab-tls -n gitlab \
  --cert=certs/gitlab.example.com.pem \
  --key=certs/gitlab.example.com-key.pem

helmfile apply -f helmfile.yaml

kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
  -o jsonpath="{.data.password}" | base64 --decode
echo
