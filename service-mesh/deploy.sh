# setup the namespace with automatic istio
kubectl create namespace sock-shop
kubectl label namespace sock-shop istio-injection=enabled
kubectl config set-context minikube --namespace=sock-shop

# setup volume
kubectl apply -f catalogue-db-pvc.yaml

# setup services
kubectl apply -f catalogue-db-service.yaml
kubectl apply -f catalogue-service.yaml
kubectl apply -f front-end-service.yaml

# setup deployments
kubectl apply -f catalogue-db-deployment.yaml
kubectl apply -f catalogue-deployment.yaml
kubectl apply -f front-end-deployment.yaml

# add another version
# kubectl apply -f catalogue-deployment-v2.yaml


# use these for manual injection
# istioctl kube-inject -f catalogue-deployment.yaml | kubectl apply -f -
# istioctl kube-inject -f catalogue-db-deployment.yaml | kubectl apply -f -
# istioctl kube-inject -f catalogue-deployment-v2.yaml | kubectl apply -f -
# istioctl kube-inject -f front-end-deployment.yaml | kubectl apply -f -
