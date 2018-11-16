#!/usr/bin/env bash

helm install \
    --name prom \
    --namespace monitoring \
    -f prometheus.yaml \
    stable/prometheus-operator
