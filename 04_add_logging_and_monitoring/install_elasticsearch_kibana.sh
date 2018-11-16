#!/usr/bin/env bash

helm repo add es-operator https://raw.githubusercontent.com/upmc-enterprises/elasticsearch-operator/master/charts/
helm install --name=elasticsearch-operator es-operator/elasticsearch-operator --set rbac.enabled=true --namespace logging

helm install --name=elasticsearch es-operator/elasticsearch -f elasticsearch.yaml --namespace logging
helm install --name=my-release stable/kibana  -f kibana.yaml  --namespace logging
helm install --name=fluent-bit stable/fluent-bit -f fluent-bit.yaml --namespace logging
