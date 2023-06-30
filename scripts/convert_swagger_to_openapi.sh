#!/bin/bash

if [ "$DEBUG" = "true" ]; then
  set -x
fi

HOSTNAME="localhost"
PORT="8080"

DEFAULT_INPUT_FILE="specs/pulsar_admin_api_swagger_revised.json"
DEFAULT_OUTPUT_FILE="specs/pulsar_admin_api_openapi_spec.json"
INPUT_FILE=${1:-DEFAULT_INPUT_FILE}
OUTPUT_FILE=${2:-DEFAULT_OUTPUT_FILE}

# start swagger converter and save the container id
CID=$(docker run -d -p ${PORT}:8080 swaggerapi/swagger-converter)

# echo "waiting for swagger converter to become ready"
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://${HOSTNAME}:${PORT}/index.html)" != "200" ]]; do 
  sleep 1;
done

# call the convert endpoint
curl -X POST http://${HOSTNAME}:${PORT}/api/convert \
           -H 'content-type: application/json' \
           --data '@specs/pulsar_admin_api_swagger_revised.json' \
           | jq \
           > specs/pulsar_admin_api_openapi_spec.json

# cleanup
docker stop $CID && docker rm $CID
