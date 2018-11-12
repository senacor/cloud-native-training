# Exercise 5 - Getting Started with Service-Meshes

In this exercise you will be installing the ISTIO service mesh in your kubernetes installation on minikube and use
some of its features in combination with your sock-shop setup:

* Tracing
* A/B Deployments
* Authentication
* Authorization

Use your minikube installation for that, not AWS.

## Step 1 - Deploy ISTIO

Deploy istio service mesh in your kubernetes.

#### First startup minikube and connect to it:

1. Make sure your minikube instance is started and your docker environment is connected as `minikube docker-env` says
2. Run the cloudnative_bash docker image to get a shell and have the `kubectl` command available 
3. Make sure the minikube is started completely. You can check by executing `kubectl get pods --all-namespaces`, 
all pods should be in status Running or Completed. Don't worry if some show Error or CrashLoopBackOff, just relax and wait. 
4. Make sure your sock-shop is still running by connecting it from your browser.

#### Next deploy ISTIO

5. Run the script `deploy_istio.sh` from this folder. It will install istio in your minikube cluster
6. Wait until the istio services are started completely. You can check by executing `kubectl get pods --all-namespaces`, 
all pods should be in status Running or Completed. Again don't worry if some show Error or CrashLoopBackOff, just relax and wait. 

## Step 2 - Enable ISTIO for your Deployments

This step is about migrating the sock-shop application to istio. This is necessary as istio requires to modify the deployments, 
so we need to install them again.

First make sure your services are still running. Access the sock-shop in the browser and it should still be there.

Next, you will migrate your front-end and catalogue services with istio. 

There is a problem with istio concerning the catalogue-db service. This service uses TCP connections and this seems
to be a problem with the current version of istio. Actually the problem is that ISTIO is trying to be too smart. By default
it activates a so called mutual TLS feature and falls back to plain connections if this doesn't work. This feature works
well with HTTP and other protocols which ISTIO knows, but for plain TCP this fails resulting in garbeled connections. 
We will fix that in a later step.

For the deployments front-end and catalogue, inject the istio sidecar into the deployment like this:

```
kubectl get deployment catalogue -o yaml | istioctl kube-inject -f - | kubectl apply -f -
kubectl get deployment front-end -o yaml | istioctl kube-inject -f - | kubectl apply -f -
```

Alternatively directly invoke from the file

```
istioctl kube-inject -f DEPLOYMENT_FILE | kubectl apply -f -
```

Now run `kubectl get pods`. It should now show that for catalogue and front-end there are 2 containers instead of one

```
$ kubectl get pods
NAME                           READY     STATUS    RESTARTS   AGE
catalogue-7dfb86d5c9-bzc87     2/2       Running   0          1m
catalogue-db-f4c8fcc4b-n5z7l   1/1       Running   0          8m
front-end-6596b6f7f7-vpv79     2/2       Running   0          54s
``` 
 
Open the sock-shop again in your browser. It should still work. If not, make sure you didn't migrate the catalogue-db deployment.

#### Let's fix the catalogue-db service

To also enable the catalogue-db service with ISTIO we need a policy to tell istio to run mutual TLS with the catalogue-db all
the time. Run this script:

```
kubectl apply -f catalogue-db-policy.yaml
```

After that, also run the kube-inject on the catalogue-db service

```
kubectl get deployment catalogue-db -o yaml | istioctl kube-inject -f - | kubectl apply -f -
```

Check again that the sock-shop still works.

If you run into problems with this, this part is not essential You can delete the policy and revert back to the non-injected
caralogue-db as a workaround.
 
## Step 3 - Let's do Tracing!

#### Make sure your Deployments match the ISTIO Requirements 

To get started, make sure your deployments and service follow the ISTIO requirements.
See https://istio.io/docs/setup/kubernetes/spec-requirements/ and fix your deployments.

Basically the requirements are about having certain labels. Make sure you also fix the selectors in the service
definitions, otherwise you might break the sock-shop.

Redeploy the modifications and open the sock-shop again in your browser. It should still work. 
If not, make sure you got the selectors in the services right.

#### Use Jaeger for Tracing

Now connect to the Jaeger frontend. It is already started in ISTIO, but not visible.
Run this command to expose it:

```
kubectl apply -f jaeger-service.yaml
```

Now run `minikube service list` to find the exposed port:

```
$ minikube service list
|--------------|--------------------------|--------------------------------|
|  NAMESPACE   |           NAME           |              URL               |
|--------------|--------------------------|--------------------------------|
...
| istio-system | jaeger                   | http://192.168.99.100:32737    |
...

```

On AWS you will have to edit the jaeger service and set it to type LoadBalancer instead. 
The LoadBalancer takes some seconds until started. You can find the URL of Jaeger in the service configuration.
Note that Jaeger is exposed on port 16686, not 80.  

Now open Jaeger at that URL.

Invoke the sock-shop frontend. You should see traces. If not, make sure you got the requirements of ISTIO right and update your deployments and services.

If you want more background, Have a look at https://istio.io/docs/concepts/policies-and-telemetry/ for the concepts. 

## Step 4 - A/B Deployments

Install a second catalogue deployment. There is an image `nextstepman/catalogue:latest` which you can use. 
Make sure that the deployment defines version numbers for your pods like in the following snippet. 

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: catalogue
  name: catalogue-v2
spec:
  template:
    metadata:
      labels:
        app: catalogue
        version: v2
  ...
    spec:
      containers:
      - image: nextstepman/catalogue:latest
...
```

Also update your first catalogue deployment to have the `version: v1` label in the pod template.

Now deploy the `catalogue-virtual-service.yaml` file with `kubectl apply -f catalogue-virtual-service.yaml`. 
You should now see that the catalogue-service flips between two versions, with v2 showing "***" on the catalogue entries, 
e.g. "Holy ***" which indicate a ranking implemented in the new service version.

As an exercise, build a rule which first directs all traffic to the v1 version.
Next update the rule so that 10 % of all traffic is routed to the v2 version.

See file `catalogue-virtual-service.yaml` for a start. Update that service for above rules. 
See https://istio.io/docs/tasks/traffic-management/traffic-shifting/ on how to do that.

## Step 5 - Enable Authentication

In this step you will add authentication into the service in order to control traffic between services.

#### Start Simple Hacking Test

Edit your catalogue service and change its type to NodePort:

```
apiVersion: v1                                                                                                                                                                                                                                                
kind: Service                                                                                                                                                                                                                                                 
metadata:                                                                                                                                                                                                                                                     
  ..
spec:                                                                                                                                                                                                                                                         
  ...
  type: NodePort                                                                                                                                                                                                                                              
```

Make sure it contains the type: entry NodePort.

After that see that the port is exposed with `minikube service list` and access it with curl.

```
$ minikube service list
...
| sock-shop    | catalogue                | http://192.168.99.100:32237    |
...
# curl  http://192.168.99.100:32237/health
{"health":[{"service":"catalogue","status":"OK","time":"2018-11-12 11:45:27.038459778 +0000 UTC"},{"service":"catalogue-db","status":"OK","time":"2018-11-12 11:45:27.038496267 +0000 UTC"}]}
```

For AWS you will have to set the catalogue service to type LoadBalanncer instead. 

This shows the service is easily accessible. Bad.

#### Enable Authentication

Enable Authentication by modifying the file `catalogue-virtual-service.yaml` and redeploying it.
You need to enable mutual TLS by adding ISTIO_MUTUAL to the policy

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
$ curl  http://192.168.99.100:32237/health
curl: (56) Recv failure: Connection reset by peer
```

Good, simple hacking disabled! But lets see if the sock-shop is still working. I think not...

To fix that we need to make sure that the front-end deployment also enables mutual TLS when communicating with the catalogue service.
To do so, add a policy like this:

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

#### Do the same for front-end

Now apply the same principle to the front-end and enable mutual TLS for it. 
To make that working, you will also need to activate a gateway

Execute `kubectl apply -f front-end-gateway.yaml`

This will create an istio gateway which also has an envoy sidecar and can carry out mutual TLS for incoming connections.
Find the address of the gateway by executing `minikube service list`:

```
...
| istio-system | istio-ingressgateway   | http://192.168.99.100:31380    |
|              |                        | http://192.168.99.100:31390    |
|              |                        | http://192.168.99.100:31400    |
|              |                        | http://192.168.99.100:32748    |

...
```

Now access the sock-shop with the first shown url, `http://192.168.99.100:31380` in above example.
The sock-shop should be accessible. The first is for port 80, so only the first one will work.

Above only works on minikube. For AWS simply skip that, it is an optional part. 

## Step 5 - Enable Authorization

Now lets play with authorization. 

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

Wait a bit, next start this

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

if you get this, you should wait a bit until the hacker container is up:
```
error: expected 'logs (POD | TYPE/NAME) [CONTAINER_NAME]'.
POD or TYPE/NAME is a required argument for the logs command
See 'kubectl logs -h' for help and examples.
```

This shows, that the rogue hacker service can still access the catalogue service. The hacker will be authenticated, 
but as the rules are permissive, still has access. 

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