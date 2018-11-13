kubectl create namespace sock-shop
kubectl config set-context $(kubectl config current-context) --namespace=sock-shop
