#!/usr/bin/env bash

docker run -it -v $(pwd):/project -v $HOME/.minikube:$HOME/.minikube -v $HOME/.aws:/root/.aws:ro -v $HOME/.ssh:/root/.ssh:ro -v $HOME/.kube:/root/.kube  cloudnative_bash:latest

