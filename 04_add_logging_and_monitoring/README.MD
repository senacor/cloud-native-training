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

    helm init

After that you have to enable the RBAC rules for HELM:

     kubectl create serviceaccount --namespace kube-system tiller
     kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
     kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' 

Otherwise you will recive an error like this later:

    Error: release elasticsearch-operator failed: namespaces "logging" is forbidden: User "system:serviceaccount:kube-system:default" cannot get namespaces in the namespace "logging"

## Task

### 1. Install Logging

For installing the loggin you will need to install the follwoing
components:
* FluentD or fluent-bit):
  https://github.com/helm/charts/tree/master/stable/fluent-bit
* ElasticSearch: https://github.com/upmc-enterprises/elasticsearch-operator
* Kibana: https://github.com/helm/charts/tree/master/stable/kibana

For the ease of the installation we provide the for the training
specific configuration as YAML-file. You can add them via -f in the HELM
Command, e.g.:

    helm install --name=fluent-bit stable/fluent-bit -f fluent-bit.yaml --namespace logging

Please install the operator and all the tree tool into the namespace
logging.

Receive the service endpoint of kibana and check if it is callable and
allows you to configure the elastic search index.




