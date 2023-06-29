

PULSAR_API_SPEC_VERSION ?= 3.0.0
PULSAR_SWAGGER_SPEC_BASE_URL ?= https://pulsar.apache.org/swagger/$(PULSAR_API_SPEC_VERSION)/
OPENAPI_CONVERTER_URL ?= https://converter.swagger.io/convert

pulsar_admin_api_swagger_spec_original_file = specs/pulsar_admin_api_swagger_original.json
pulsar_admin_api_swagger_spec_modified_file = specs/pulsar_admin_api_swagger_revised.json

pulsar_admin_api_openapi_spec_json_file = specs/pulsar_admin_api_openapi_spec.json
pulsar_admin_api_openapi_spec_yaml_file = specs/pulsar_admin_api_openapi_spec.yaml

default: generate

update: download-specs revise-specs

curl:
	@type curl >/dev/null 2>&1 || echo "`curl` command not found in PATH, please install curl before continuing"

oapi-codegen:
	@type oapi-codegen >/dev/null 2>&1 || go install github.com/deepmap/oapi-codegen/cmd/oapi-codegen@v1.12

download-specs: curl
	curl $(PULSAR_SWAGGER_SPEC_BASE_URL)/swagger.json -o $(pulsar_admin_api_swagger_spec_original_file)

# fix some bugs in the swagger spec
revise-specs:
	go run scripts/revise_pulsar_admin_api_spec.go $(pulsar_admin_api_swagger_spec_original_file) $(pulsar_admin_api_swagger_spec_modified_file)

# TODO: this part is not working yet
convert-to-openapi:
	curl -X POST \
	  -H 'Content-Type: application/json' \
	  -H 'Accept: application/json' \
	  --data @$(pulsar_admin_api_swagger_spec_file) \
	  $(OPENAPI_CONVERTER_URL) 

generate-pulsar-admin-api-client: oapi-codegen
	oapi-codegen -config config/pulsar_admin_api_oapi_config.yaml $(pulsar_admin_api_openapi_spec_yaml_file)

generate: generate-pulsar-admin-api-client

build:
	go build ./...

.PHONY: convert-spec-openapi curl download-pulsar-specs generate generate-pulsar-admin-api-client revise-specs


