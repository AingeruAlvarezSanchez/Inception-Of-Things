k3d cluster delete inception

#sudo rm -f /usr/local/bin/k3d

#rm ~/.kube/config

docker ps -a | grep k3d | awk '{print $1}' | xargs docker rm -f
docker network ls | grep k3d | awk '{print $1}' | xargs docker network rm
docker volume ls | grep k3d | awk '{print $2}' | xargs docker volume rm

rm -rf ~/.config/k3d
sudo rm -rf /etc/rancher/k3s
