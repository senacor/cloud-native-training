#!/usr/bin/env bash


aws s3api create-bucket \
    --bucket ${DOMAIN}-state-store \
    --create-bucket-configuration LocationConstraint=${REGION} \


aws s3api put-bucket-encryption --bucket ${DOMAIN}-state-store --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
