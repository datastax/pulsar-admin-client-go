#!/bin/bash

# Start container and save the container id
CID=$(docker run -d swaggerapi/swagger-generator-v3-minimal)
# allow for startup
sleep 5
# Get the IP of the running container
GEN_IP=$(docker inspect --format '{{.NetworkSettings.IPAddress}}'  $CID)
# Execute an HTTP request and store the download link
curl -X POST \
           http://localhost:8080/api/convert \
           -H 'content-type: application/json' \
           -d '@specs/pulsar_admin_api_spec.json' # > ../specs/pulsar_admin_api_openapi.json
# Shutdown the swagger generator image
docker stop $CID && docker rm $CID
