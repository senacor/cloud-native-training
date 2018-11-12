# Exercise 2

Create Kubernetes ressource files for the Sock-Shop. Do so by using the kubernetes kompose tool, which takes an docker-compose.yaml file as input and creates kubernetes files. 

There is a `docker-compose.yaml` file in this folder. You can replace that with your version if you like. 

## Step 1

1. start minikue if not done yet: See script `start_minikube.sh`
2. Connect your docker environment to minikube in your shell by executing `minikube docker-env` and doing what it says. 
You must do that each time you open your shell. 
3. Slim down your docker-compose file, remove edge-router if still in.
We don't use it with kubernetes.
4. Run `kompose convert` from within the cloudnative_bash docker image 
5. Review the created files
6. Create a namespace with `kubectl create namespace sock-shop`
7. Select namespace with `kubectl config set-context minikube --namespace=sock-shop`
8. Deploy to minikube by running `kubectl apply -f .`
9. Check if the deployment runs smoothly

Note: if you run `kubectl apply -f .` this might find your docker-compose.yaml file in the current folder and complain about it not having an api. Kubectl will ignore that and so can you. 

To check if you did all right, check if the pods did start

```
$ kubectl get pods
NAME                            READY     STATUS    RESTARTS   AGE
catalogue-67f85bd666-28zll      1/1       Running   0          9m
catalogue-db-5cc5c5b4b6-s8lkn   1/1       Running   0          9m
front-end-74464645d-mfwh7       1/1       Running   0          36s
```

The pods should be in status "Running".

Now lets check if we can access the service. 

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

No node port yet - we do it in the next task

## Step 2

1. Update the front-end service to be of type node port
2. redeploy
3. run the `minikube service list` again

Now there should be an URL. Access that and you should see the socks shop

## Step 3

1. Update the deployments to contain valid probes for the font-end as well as the catalog-db service
2. Redeploy
3. Check that all pods come up in status "READY 1/1". This will take longer, depending on your settings on the probes. 

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

## Optional Steps 4

1. Scale up the front-end and catalog deployment and see what happens
2. Kill a pod and see what happens
3. Create a volume for the catalog-db and redeploy

