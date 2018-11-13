# create namespace an enable automatic istio
kubectl create namespace hacker
kubectl label namespace hacker istio-injection=enabled

# create hacker deployment
kubectl apply -f hacker-deployment.yaml -n hacker

# use this for manual injection
# istioctl kube-inject -f hacker-deployment.yaml | kubectl apply -f - -n hacker

