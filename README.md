# Cloud Native Training

## Getting Started

### Required Installations

For this training you will need the following software installed on your system. Download and install them:

* Docker (for Mac, PC, Linux, ...), see https://docs.docker.com/install/
* Minikube, see https://kubernetes.io/docs/tasks/tools/install-minikube/
* Virtualbox, see https://www.virtualbox.org/

If you already have them installed, make sure that you have the newest versions of these tools, or update them if not.

### Setup Tasks

Execute the following steps to make sure your tools are installed correctly and to download some images you will require ahead, in order not to have bandwith problems during the training.

Execute these steps:

```
# start minikube with at least 6 GB of memory, better with 8 GB

minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.10.0 --vm-driver=virtualbox
    
# get instructions how to connect to minikube with docker
minikube docker-env

# do as suggested. For linux or mac this is eval $(minikube docker-env), 
# for windows something like @FOR /f "tokens=*" %i IN ('minikube docker-env') DO @%i
eval $(minikube docker-env)

# pull images to the minikube docker instance
docker pull weaveworksdemos/catalogue-db:0.3.0
docker pull weaveworksdemos/catalogue:0.3.5
docker pull weaveworksdemos/edge-router:0.1.1
docker pull weaveworksdemos/front-end:0.3.12

# and stop minikube again

minikube stop 

```