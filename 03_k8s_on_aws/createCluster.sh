#!/usr/bin/env bash

kops create cluster \
    --zones=${REGION}a,${REGION}b,${REGION}c \
    --bastion --topology private --networking flannel \
    --cloud-labels="CostCenter=cloudnative" \
    ${NAME}

kops update cluster ${NAME} --yes
