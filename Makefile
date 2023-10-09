

PULSAR_API_SPEC_VERSION ?= 3.0.0
PULSAR_SWAGGER_SPEC_BASE_URL ?= https://pulsar.apache.org/swagger/$(PULSAR_API_SPEC_VERSION)/

OAPI_CODEGEN_VERSION = v1.15

pulsar_admin_api_swagger_spec_original_file = specs/pulsar_admin_api_swagger_original.json
pulsar_admin_api_swagger_spec_modified_file = specs/pulsar_admin_api_swagger_revised.json

pulsar_admin_api_openapi_spec_json_file = specs/pulsar_admin_api_openapi_spec.json
pulsar_admin_api_openapi_spec_yaml_file = specs/pulsar_admin_api_openapi_spec.yaml

default: generate

update: download-specs revise-specs

curl:
	@type curl >/dev/null 2>&1 || echo "`curl` command not found in PATH, please install curl before continuing"

docker:
	@type docker >/dev/null 2>&1 || echo "`docker` command not found in PATH, please install curl before continuing"

jq:
	@type jq >/dev/null 2>&1 || echo "`jq` command not found in PATH, please install curl before continuing"

yq:
	@type yq >/dev/null 2>&1 || echo "`yq` command not found in PATH, please install curl before continuing"

oapi-codegen:
	@type oapi-codegen >/dev/null 2>&1 || go install github.com/deepmap/oapi-codegen/cmd/oapi-codegen@$(OAPI_CODEGEN_VERSION)

download-specs: curl
	curl $(PULSAR_SWAGGER_SPEC_BASE_URL)/swagger.json -o "$(pulsar_admin_api_swagger_spec_original_file)"

# fix some bugs in the swagger spec
revise-specs:
	go run scripts/revise_pulsar_admin_api_spec.go "$(pulsar_admin_api_swagger_spec_original_file)" "$(pulsar_admin_api_swagger_spec_modified_file)"

openapi-json: docker jq
	scripts/convert_swagger_to_openapi.sh "$(pulsar_admin_api_swagger_spec_modified_file)" "$(pulsar_admin_api_openapi_spec_json_file)"

openapi-yaml: yq
	cat "$(pulsar_admin_api_openapi_spec_json_file)" | yq --prettyPrint > $(pulsar_admin_api_openapi_spec_yaml_file)

generate-pulsar-admin-api-client: oapi-codegen
	oapi-codegen -config config/pulsar_admin_api_oapi_config.yaml "$(pulsar_admin_api_openapi_spec_yaml_file)"

generate: generate-pulsar-admin-api-client

build:
	go build ./...

.PHONY: convert-spec-openapi curl download-pulsar-specs generate generate-pulsar-admin-api-client openapi-yaml revise-specs


