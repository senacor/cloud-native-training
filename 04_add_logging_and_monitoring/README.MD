# Exercise 4: Add Logging and Monitoring

## Description:

In this exercise we will add a monitoring and Logging solution to our
kubernetes cluster. We will use the EFK-Stack for Logging and Prometheus
and Grafana for monitoring.

For the installation we will use a combination of HELM-Charts and Operators.

After we have successfully installed to logging and monitoring we have
will start gathering some information from it.



## Prerequisites

Before you can use HELM you have to initialize it locally:

    ./helm_initialize.sh

Internall the command:

    helm init 

will be called. After that the nessasary RABC rules will be created:

     kubectl create serviceaccount --namespace kube-system tiller
     kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
     kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' 

Otherwise you will recive an error like this later:

    Error: release elasticsearch-operator failed: namespaces "logging" is forbidden: User "system:serviceaccount:kube-system:default" cannot get namespaces in the namespace "logging"

## Logging Tasks

### 1. Install the EFK Stack

For installing the loggin you will need to install the follwoing
components:
* FluentD or fluent-bit):
  https://github.com/helm/charts/tree/master/stable/fluent-bit
* ElasticSearch: https://github.com/upmc-enterprises/elasticsearch-operator
* Kibana: https://github.com/helm/charts/tree/master/stable/kibana

For the ease of the installation we provide the for the training
specific configuration as YAML-file.

By calling the script:

    ./install_elasticsearch_kibana.sh

Everything will be installed in the namespace logging.

**Caution**: It might be better to increase the number of node to 3
because the static set of the elastic search cluster might get trouble
if the persistentVolumnClain will be created in the AZ with the master
and no other nodes.

Receive the service endpoint of kibana and check if it is callable and
allows you to configure the elastic search index.

### 2. Configure the Kibana search to get useable results.

Directly after the index creation the search of the kibana gui is not
very usable, try to optimize the view of the logiles to get better
results.

## Monitoring Tasks

### 1. Install the Promethues / Grafana monitoring

The monitoring solution consists of the two tools Prometheus and
Grafana. You can install both tools with the Prometheus Operator HELM
Chart:
https://github.com/helm/charts/tree/master/stable/prometheus-operator

In this training use:

    ./install_prometheus.sh

It will install everythink into the namespace monitoring.

This will startup the prometheus and Grafana with a preinstalled
standard kubernetes configuration.

To reach the GUI you have to configure the services to type
Loadbalancer.

### 2. Reach Grafana and experiment with the dashboards

Open the Grafana dashboard. You can lookup the credentials from the
kubernetes secret.

    kubectl get secret -n monitoring

There are serveral dashbaords available. You can although download and
include new dahsborad or create or modify them.

### 3. Have a look in to the Prometheus GUI

Login in to the prometheus gui and have a look onto the prometheus
scrapes.

### 4. (Optional) Try to create a service Monitor for our cataloge service.

Try to create a serice Monitor for our cataloge service. (see: https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md)


