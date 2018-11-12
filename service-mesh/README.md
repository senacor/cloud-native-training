# Exercise 4

This exercise is about installing istio service mesh in your kubernetes installation on minikube and using some of its features in combination with your sock-shop setup:

* Tracing
* A/B Deployments
* Authentication

## Step 1 - Deploy ISTIO

Deploy istio service mesh in your kubernetes.

##### First startup minikube and connect to it:

1. Make sure your minikube instance is started and your docker environment is connected as `minikube docker-env` says
2. Run the cloudnative_bash docker image to get a shell and have the `kubectl` command 
3. Make sure the minikube is started completely. You can check by executing `kubectl get pods --all-namespaces`, 
all pods should be in status running 
4. Make sure your sock-shop is still running. 

##### Next deploy istio

5. Run the script `deploy_istio.sh` from this folder. It will install istio in your minikube cluster
6. Wait until the istio services are started completely. You can check by executing `kubectl get pods --all-namespaces`, 
all pods should be in status Running or Completed. Don't worry if some show Error or CrashLoopBackOff, just relax and wait. 

## Step 2 - Enable ISTIO for your Deployments

This step is about migrating the sock-shop application to istio. This is necessary as istio will modify the deployments, 
so we need to install them again.

First make sure your services are still running. Access the sock-shop in the browser and it should still be there.

Next, redeploy your front-end and catalogue services with istio. 
There is a problem with istio concerning the catalogue-db service. This service uses TCP connections and this seems
to be a problem with istio.

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
 
Open the sock-shop again. It should still work. 
 
## Step 3 - Let's do Tracing!

##### Verify requirements

To get started, make sure your deployments and service follow the ISTIO requirements.
See https://istio.io/docs/setup/kubernetes/spec-requirements/ and fix your deployments

##### Use Jaeger for Tracing

Now connect to the Jaeger frontend. It is already started in ISTIO, but not visible.
Run this command to expose it from this folder:

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

Now open Jaeger at that URL.

Invoke the sock-shop frontend. You should see traces. If not, make sure you got the requirements of ISTIO right and update your deployents and services.

##### More Info

Have a look at https://istio.io/docs/concepts/policies-and-telemetry/ for the concepts. 

# Step 4 - A/B Deployments

Install a second catalogue deployment. There is an image `nextstepman/catalogue:latest` which you can use. 
Make sure that the deployment shows version numbers like in the following snippet:

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
Now deploy the *catalogue-virtual-service.yaml* file with `kubectl apply -f catalogue-virtual-service.yaml`. 
You should now see that the catalogue-service flips between two versions, with v2 showing "***" on the catalogue entries, 
e.g. "Holy ***" which indicate a ranking implemented in the new service version.

As an exercise, build a rule which first directs all traffic to the v1 version.
Next update the rule so that 10 % of all traffic is routed to the v2 version.

See file `catalogue-virtual-service.yaml` for a start. Update that service for above rules. 
See https://istio.io/docs/tasks/traffic-management/traffic-shifting/ on how to do that.

# Step 5 - Enable Authentication

In this step we will add authentication into the service in order to control traffic between services.

##### Start Simple Hacking Test

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

This shows the service is still accessible. Bad.

##### Enable Authentication

Enable Authentication by modifying the file `catalogue-virtual-service.yaml` and redeploying it.
You need to enable mutual tls by adding ISTIO_MUTUAL to the policy

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

Good, simple hacking disabled! But lets see if the sock-shop is still working. I guess not...

To fix that we need to make sure that the front-end deployment also enables mtls when communicating with the catalogue service.
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

##### Do the same for front-end

Now apply the same principle to the front-end and enable mtls for it. 
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
The sock-shop should be accessible. 
