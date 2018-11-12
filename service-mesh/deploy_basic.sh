# setup the namespace with automatic istio
kubectl create namespace sock-shop
# kubectl label namespace sock-shop istio-injection=enabled
kubectl config set-context minikube --namespace=sock-shop

kubectl apply -f front-end-gateway.yaml
kubectl apply -f rbac-permissive.yaml
