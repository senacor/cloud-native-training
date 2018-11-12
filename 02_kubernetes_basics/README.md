# Exercise 2 - Deploy Sock-Shop to Kubernetes

In this exercise you will create Kubernetes ressource files for the Sock-Shop. 
You will use the kubernetes kompose tool, which takes an docker-compose.yaml file as input and creates kubernetes files. 

There is a `docker-compose.yaml` file in this folder. You can replace that with your version if you like. 

## Step 1

1. Make sure minikube is started. Run script `start_minikube.sh` if not done yet
2. Connect your docker environment to minikube in your shell by executing `minikube docker-env` and doing what it says. 
You must do that each time you open your shell. 
3. Slim down your docker-compose file, remove edge-router if still in.
We don't use it with kubernetes.
4. Run `kompose convert` from within the cloudnative_bash docker image 
5. Review the created files and modify them until satisfied. 
6. Run script `deploy.sh` to create a namespace `sock-shop` and set your config to default to it. 
7. Deploy to minikube by running `kubectl apply -f .`

Note: if you run `kubectl apply -f .` this might find your docker-compose.yaml file in the current folder and complain about it not having an api. Kubectl will ignore that and so can you. 

To check if you did all right, check if the pods did start by executing `kubectl get pods` like shown below:

```
$ kubectl get pods
NAME                            READY     STATUS    RESTARTS   AGE
catalogue-67f85bd666-28zll      1/1       Running   0          9m
catalogue-db-5cc5c5b4b6-s8lkn   1/1       Running   0          9m
front-end-74464645d-mfwh7       1/1       Running   0          36s
```

The pods should be in status "Running".

Now lets check if we can access the service. Run `minikube service list` in a shell outside of the docker image. 
See below content for an example: 

```
$ minikube service list
|-------------|----------------------|-----------------------------|
|  NAMESPACE  |         NAME         |             URL             |
|-------------|----------------------|-----------------------------|
| default     | kubernetes           | No node port                |
| kube-system | kube-dns             | No node port                |
| kube-system | kubernetes-dashboard | No node port                |
| sock-shop   | catalogue            | No node port                |
| sock-shop   | catalogue-db         | No node port                |
| sock-shop   | front-end            | No node port                |
|-------------|----------------------|-----------------------------|
```

This output shows that there is node port yet - so we cannot try out the sock-shop yet. We do it in the next task

## Step 2

1. Update the front-end service to be of type node port
2. redeploy
3. run the `minikube service list` again

This shows an example service with NodePort set:

```
apiVersion: v1
kind: Service
metadata:
  labels:
    io.kompose.service: front-end
  name: front-end
  namespace: sock-shop
spec:
  ports:
  - name: "http"
    port: 80
    protocol: TCP
    targetPort: 8079
  selector:
    io.kompose.service: front-end
  type: NodePort
```

Now after running `minikube service list` there should be an URL. Access that and you should see the socks shop

## Step 3

1. Update the deployments to contain valid probes for the font-end as well as the catalogue service.
2. Redeploy
3. Check that all pods come up in status "READY 1/1". This will take longer, depending on your settings on the probes. 

See https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ for reference. 

For testing, you can access your pods to find out ports etc like this:

```
$ kubectl get pods
NAME                            READY     STATUS    RESTARTS   AGE
catalogue-67f85bd666-28zll      1/1       Running   0          13m
catalogue-db-5cc5c5b4b6-s8lkn   1/1       Running   0          13m
front-end-74464645d-mfwh7       1/1       Running   0          5m

$ kubectl exec -it catalogue-67f85bd666-28zll sh

/ $ wget http://localhost:80/health -O-

Connecting to localhost:80 (127.0.0.1:80)
{"health":[{"service":"catalogue","status":"OK","time":"2018-11-08 16:36:36.336317212 +0000 UTC"},{"service":"catalogue-db","status":"OK","time":"2018-11-08 16:36:36.336541455 +0000 UTC"}]}
-                    100% |*******************************|   190   0:00:00 ETA
```

Use the wget command for your probes, do not use the `httpGet` methods. The `httpGet` is problematic with ISTIO
in our service mesh exercise later. 

## Step 4

1. Scale up the front-end and catalogue deployment to 2 replicas. Do you know why you shouldn't scale up catalogue-db?
2. Next create a *ping* script to check that your service is alive.
You can use a script like this: 

```
while true; do curl -s -o /dev/null -w "%{http_code}\n" http://192.168.99.100:31703; sleep 1; done`
```

Or if you like write a small gatling script and I will add it in future trainings ;-)

Now kill one pod by `kubectl delete pod POD-NAME` and see what happens. If your probe works correctly, there should be NO failure. 

## Optional Step 5

Create a volume for the catalogue-db deployment. 

For more info see Kubernetes documents on volumes: https://kubernetes.io/docs/concepts/storage/volumes/

