# Exercise 5 - Getting Started with Service-Meshes

In this exercise you will be installing the ISTIO service mesh in your kubernetes installation on minikube and use
some of its features in combination with your sock-shop setup:

* Deploy ISTIO and Migrate Sock-Shop (Required Step 1 and 2)
* Tracing (Optional Step 3)
* A/B Deployments (Optional Step 4)
* Authentication and Authorization (Optional Step 5 and 6)

The Steps 3 until 6 are optional. You can either do Tracing, A/B Deployments
or Authentication and Authorization or all of them if you like. The last one is the most difficult.

You can do them in any order, but if you do Authorization you must first complete Authentication. 

You can use your AWS installation for all exercises.

## Required Step 1 - Deploy ISTIO

Deploy istio service mesh in your kubernetes.

#### Preparation

1. Run the cloudnative_bash docker image to get a shell and have the `kubectl` command available 
2. Make sure the AWS kubernetes cluster is in good health. You can check by executing `kubectl get pods --all-namespaces`, 
all pods should be in status Running or Completed. 
3. Make sure your sock-shop is still running by connecting it from your browser.

#### Next deploy ISTIO

4. Run the script `deploy_istio.sh` from this folder. It will install istio in your kubernetes cluster
5. Wait until the istio services are started completely. You can check by executing `kubectl get pods --all-namespaces`, 
all pods should be in status Running or Completed. Again don't worry if some show Error or CrashLoopBackOff, just relax and wait. 

## Required Step 2 - Migrate Sock-Shop to ISTIO 

This step is about migrating the sock-shop application to istio. This is necessary as istio requires to modify the deployments, 
so we need to install them again.

First make sure your services are still running. Access the sock-shop in the browser and it should still be there.

Next, you will migrate your front-end and catalogue services with istio. 

For the deployments front-end, catalogue and catalog-db, inject the istio sidecar into the deployment by executing the following steps:

```
kubectl get deployment catalogue -o yaml | istioctl kube-inject -f - | kubectl apply -f -
kubectl get deployment front-end -o yaml | istioctl kube-inject -f - | kubectl apply -f -
kubectl get deployment catalogue-db -o yaml | istioctl kube-inject -f - | kubectl apply -f -
```

Now run `kubectl get pods`. It should now show that for catalogue and front-end there are 2 containers instead of one

```
$ kubectl get pods
NAME                           READY     STATUS    RESTARTS   AGE
catalogue-7dfb86d5c9-bzc87     2/2       Running   0          1m
catalogue-db-f4c8fcc4b-n5z7l   2/2       Running   0          8m
front-end-6596b6f7f7-vpv79     2/2       Running   0          54s
``` 
 
Still one more thing to do. The catalogue-db service needs some special handling, as it is a TCP service. Run this script:

```
kubectl apply -f catalogue-db-policy.yaml
```

This step is required to make the catalogue-db service work with istio, as it is a TCP service. 
Now check that the sock-shop still works, before doing the part:

#### Make sure your Deployments match the ISTIO Requirements 

Before proceeding to one of the following optional steps, make sure your deployments and service follow the ISTIO requirements.

Basically the requirements are about having certain labels. 

In short: your yaml files must define labels app: and version: for your deployments and services. Make sure to also fix the 
service selector correctly. Also make sure the ports in catalogue and catalogue-db are named "http".

Example for Deployment:

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  creationTimestamp: null
###### note the labels here ######
  labels:
    app: catalogue
  name: catalogue
spec:
  replicas: 1
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
###### note the labels here ######
      labels:
        app: catalogue
        version: v1
...       

```

Note that the deployment has the version only in the template, not on the deployment itself.

Example for Service:

```
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
###### note the labels here ######
  labels:
    app: catalogue
  name: catalogue
spec:
  type: NodePort
  ports:
###### note the name here ######
  - name: "http"
    port: 80
    targetPort: 80
    protocol: TCP
###### note the selector here ######    
  selector:
    app: catalogue
status:
  loadBalancer: {}
```

Be aware that the service does not have the version: in the selector, only the deployment.

Redeploy the modifications and open the sock-shop again in your browser. It should still work. 
If not, make sure you got the selectors in the services right.

For more background see https://istio.io/docs/setup/kubernetes/spec-requirements/
 
## Optional Step 3 - Let's do Tracing!

#### Use Jaeger for Tracing

Connect to the Jaeger frontend. It is already started in ISTIO, but not visible.
Run this command to expose it via a LoadBalancer:

```
kubectl apply -f jaeger-service.yaml
```

The LoadBalancer takes some seconds until started. You can find the URL of Jaeger in the service configuration.
Note that Jaeger is exposed on port 16686, not 80.  

Now open Jaeger at that URL.

Invoke the sock-shop frontend. You should see traces. If not, make sure you got the requirements of ISTIO right and update your deployments and services.

If you want more background, Have a look at https://istio.io/docs/concepts/policies-and-telemetry/ for the concepts. 

## Optional Step 4 - A/B Deployments

Install a second catalogue deployment. There is an image `nextstepman/catalogue:latest` which you can use. So just copy the 
catalogue deployment, give it a different name and change the image.

Make sure that the deployment defines a version number for your pods like in the following snippet. 
Note that only the name is different, the labels still says `app: catalogue`. This is because 2 deployments
cannot exist with the same name.

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: catalogue
###### note the name here ######    
  name: catalogue-v2
spec:
  template:
    metadata:
###### note the version label here ######    
      labels:
        app: catalogue
        version: v2
...
    spec:
      containers:
      - image: nextstepman/catalogue:latest
...
```

Also update your first catalogue deployment to have the `version: v1` label in the pod template if not 
done yet.

Now deploy the `catalogue-virtual-service.yaml` file with `kubectl apply -f catalogue-virtual-service.yaml`. 
You should now see that the catalogue-service flips between two versions, with v2 showing "***" on the catalogue entries, 
e.g. "Holy ***" which indicate a ranking implemented in the new service version.

As an exercise, build a rule which first directs all traffic to the v1 version.
Next update the rule so that 10 % of all traffic is routed to the v2 version.

See file `catalogue-virtual-service.yaml` for a start. Update that service for above rules. 
See https://istio.io/docs/tasks/traffic-management/traffic-shifting/ on how to do that.

## Optional Step 5 - Enable Authentication

In this step you will add authentication into the service in order to control traffic between services.

#### Start Simple Hacking Test

Edit your catalogue service and change its type to LoadBalancer:

```
apiVersion: v1                                                                                                                                                                                                                                                
kind: Service                                                                                                                                                                                                                                                 
metadata:                                                                                                                                                                                                                                                     
  ..
spec:                                                                                                                                                                                                                                                         
  ...
  type: LoadBalancer                                                                                                                                                                                                                                              
```

Make sure it contains the type: entry NodePort.

After that see the url which is exposed on AWS with `kubectl describe service catalogue`.

```
curl  http://blablablablablablabla-123456789.eu-central-1.elb.amazonaws.com/health
{"health":[{"service":"catalogue","status":"OK","time":"2018-11-12 11:45:27.038459778 +0000 UTC"},{"service":"catalogue-db","status":"OK","time":"2018-11-12 11:45:27.038496267 +0000 UTC"}]}
```

This shows the service can be make accessible easily. 
Even if not exposed with a LoadBalancer, any other Container in the Kubernetes cluster could access it. 

#### Enable Authentication

Enable Authentication by modifying the file `catalogue-virtual-service.yaml`.
You need to enable mutual TLS by adding ISTIO_MUTUAL to the DestinationRule like shown below and deploy it with 
`kubectl apply -f catalogue-virtual-service.yaml`.

```
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: catalogue
spec:
  host: catalogue
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
```

Again try our hacking

```
$ curl  http://blablablablablablabla-123456789.eu-central-1.elb.amazonaws.com/health
curl: (56) Recv failure: Connection reset by peer
```

Good, simple hacking disabled! But lets see if the sock-shop is still working. I think not...

To fix that we need to make sure that the front-end deployment also enables mutual TLS when communicating with the catalogue service.
To do so, add the policy in file catalogue-virtual-service.yaml like this:

```
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "catalogue"
spec:
  targets:
  - name: catalogue
  peers:
  - mtls: {}
```

Again deploy the modified file with `kubectl apply -f catalogue-virtual-service.yaml`. 

Now check the sock-shop again. It should work again, but the simple hacking should still be blocked. 

## Optional Step 6 - Enable Authorization

Now lets play with authorization. This only works if you turned on Authentication already. If not, do that step first. 

#### Make sure the ports are named

It is essential that your services define their ports with the correct name which is one
of the requirements of ISTIO. 

You can check like this:

```
kubectl get service front-end -o=jsonpath="----- {.spec.ports[].name} -----"
kubectl get service catalogue -o=jsonpath="----- {.spec.ports[].name} -----"
kubectl get service catalogue-db -o=jsonpath="----- {.spec.ports[].name} -----"
``` 

If it outputs `----- http -----` for front-end and catalogue and something else for the catalogue-db then all is well.
The reason is, that the RBAC feature in ISTIO will only work if the ports are named correctly. 

#### Enable RBAC

Lets blindly turn RBAC on and see what happens. Run this script

```
kubectl apply -f rbac-on.yaml
```

Try to access the sock-shop. At first it might work, but after some time you will get this:

```
RBAC: access denied
```

The reason is that RBAC has an deny-all default. 
To deal with this, turn RBAC on but with an allow-all policy. Run this script:

```
kubectl apply -f rbac-permissive.yaml
```

Check the socks shop again. All should be fine.

#### Hack the Catalogue Service

Now test if the services are still hackable. There is a folder `hacker` which starts up an container which tries
to access the catalogue service. It simply runs a wget in a loop and tries to access the catalogue service. 

Start it with
```
cd hacker
sh deploy.sh
```

Wait a a few seconds , next start this

```
sh getlog.sh
```

It will output something like this:

```
hacking catalogue
Connecting to catalogue.sock-shop.svc.cluster.local (10.99.214.77:80)
-                    100% |*******************************|   190   0:00:00 ETA
{"health":[{"service":"catalogue","status":"OK","time":"2018-11-13 14:34:50.153683049 +0000 UTC"},{"service":"catalogue-db","status":"OK","time":"2018-11-13 14:34:50.153690592 +0000 UTC"}]}
```

This shows, that the rogue hacker service can still access the catalogue service. The hacker will be authenticated, 
but as the rules are permissive, still has access. 

If you get an error like the following, you should wait a bit longer until the hacker container is up:

```
error: expected 'logs (POD | TYPE/NAME) [CONTAINER_NAME]'.
POD or TYPE/NAME is a required argument for the logs command
See 'kubectl logs -h' for help and examples.
```

#### Get Authorizations right

Your job is to configure authorization right:

* The front-end service should still be accessible
* The catalogue service should only be accessible for the front-end service

See https://istio.io/docs/tasks/security/role-based-access-control/ for more infos. The basic idea is that you will have 
to add an service account to the front-end service and allow access to the catalogue service only for that. 

Make sure that mutual TLS is enabled for the catalogue service, otherwise user authentication won't work. 

After that, the hacker component log should output this:

```
hacking catalogue
Connecting to catalogue.sock-shop.svc.cluster.local (10.99.214.77:80)
wget: server returned error: HTTP/1.1 403 Forbidden
```

And the sock-shop should still work as usual.
