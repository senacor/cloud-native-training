#!/usr/bin/env bash
domain=cloudnative.senacor.com

profile=senacor

export REGION=eu-central-1
export TEAM=$1
export DOMAIN=${TEAM}.${domain}


export NAME=${DOMAIN}
export KOPS_STATE_STORE=s3://${DOMAIN}-state-store
export AWS_PROFILE=${profile}
export AWS_SDK_LOAD_CONFIG=1

