# Exercise 4

This exercise is about installing istio service mesh in your kubernetes installation on minikube and using some of its features in combination with your sock-shop setup:

* Tracing
* A/B Deployments
* Authorization

## Step 1

Deploy istio service mesh in your kubernetes.

##### First startup minikube and connect to it:

1. Start your minikube instance if not done yet or stopped
2. Connect your docker environment to minikube in your shell by executing `minikube docker-env` and doing what it says. 
You must do that each time you open a new shell.
3. Run the cloudnative_bash docker image to get a shell with kubectl command in it. The following commands must be executed there. 
4. Wait until the minikube is started completely. You can check by executing `kubectl get pods --all-namespaces`, 
all pods should be in status running 

##### Next deploy istio

5. Run the script `deploy_istio.sh` from this folder. It will install istio in your minikube cluster
6. Wait until the istio services are started completely. You can check by executing `kubectl get pods --all-namespaces`, 
all pods should be in status running 

## Step 2

This step is about migrating the sock-shop application to istio. This is necessary as istio will modify the deployments, 
so we need to install them again.

##### Basic Deployment

1. Undeploy your sock-shop application. This is because the istio setup will break things. Run `undeploy.sh` script 
2. Recreate the sock-shop namespace with automatic istio injection enabled and some basic elements. 
Run the `deploy_basic.sh` script

##### Redeploy the sock-shop

3. Redeploy the sock-shop
4. Wait until the pods are started

##### Find the ingress gateway

We cannot use the NodePort as istio will block it. We need to use an ISTIO gateway now.
Run `minikube service list` from a commandline outside of docker to find it.

```
$ minikube service list
|--------------|--------------------------|--------------------------------|
|  NAMESPACE   |           NAME           |              URL               |
|--------------|--------------------------|--------------------------------|
| default      | kubernetes               | No node port                   |
...
| istio-system | istio-ingressgateway     | http://192.168.99.100:31380    |
|              |                          | http://192.168.99.100:31390    |
|              |                          | http://192.168.99.100:31400    |
|              |                          | http://192.168.99.100:31765    |
....

```

Pick the first one which in above script is `http://192.168.99.100:31380` and connect to it. You should get the sock-shop.

Hint: if your pods don't come to their feet disable the probes temporarily. 



