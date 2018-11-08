#!/usr/bin/env bash

docker run -it -v ${pwd}:/porject -v $HOME/.aws:/root/.aws:ro -v $HOME/.ssh:/root/.ssh:ro -v $HOME/.kube:/root/.kube  cloudnative_bash:latest
