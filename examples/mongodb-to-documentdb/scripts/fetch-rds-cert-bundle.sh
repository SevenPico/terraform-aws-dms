#!/bin/bash
set -e

query=$(cat) # json query from stdin

aws_region=$(echo $query | jq -r .aws_region)

bundle=$(curl https://truststore.pki.rds.amazonaws.com/$aws_region/$aws_region-bundle.pem)

jq -n --arg bundle "$bundle" '{"bundle": $bundle}'
