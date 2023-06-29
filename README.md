# pulsar-admin-client-go

A Pulsar Admin client library in Go.  The sources are generated from the Apache
Pulsar swagger [REST API definition](https://pulsar.apache.org/admin-rest-api/).

# Example usage

Example program to get list of topics in a namespace

       import (
              "context"
              "io"
              "log"
              "net/http"
              "os"

              "github.com/datastax/pulsar-admin-client-go/src/pulsaradmin"
       )

       func main() {

              // PULSAR_ADMIN_URL should be in the form 'https://myserver.com/admin/v2'
              url := os.Getenv("PULSAR_ADMIN_URL")
              if url == "" {
                     log.Fatal("missing required environment var 'PULSAR_ADMIN_URL'")
              }
              token := os.Getenv("PULSAR_ADMIN_TOKEN")
              if token == "" {
                     log.Fatal("missing required environment var 'PULSAR_ADMIN_TOKEN'")
              }
              client, _ := pulsaradmin.NewClient(url, func(c *pulsaradmin.Client) error {
                     c.RequestEditors = append(c.RequestEditors, func(ctx context.Context, req *http.Request) error {
                            req.Header.Set("User-Agent", "go")
                            req.Header.Set("Authorization", token)
                            return nil
                     })
                     return nil
              })

              tenant := "my-tenant"
              namespace := "my-namespace"
              params := &pulsaradmin.NamespacesGetTopicsParams{}
              resp, err := client.NamespacesGetTopics(context.Background(), tenant, namespace, params)
              if err != nil {
                     log.Fatalf("failed to get topics for namespace '%v': %v", tenant+"/"+namespace, err)
              } else {
                     log.Printf("status code: %v", resp.StatusCode)
                     bodyBytes, err := io.ReadAll(resp.Body)
                     if err != nil {
                            log.Fatalf("failed to read response body: %v", err)
                     }
                     resp.Body.Close()
                     log.Print(string(bodyBytes))
              }
       }


# Updating the sources

1. Get the latest swagger spec

       make download-specs

2. Revise the spec to fix duplicate endpoint IDs

       make revise-specs

3. Convert the swagger spec to openapi

   TODO: this step should be automated in the future, for now use https://editor-next.swagger.io/
   to convert the swagger json to openapi 3.0 json and then to openapi yaml.
   Save the resulting file to `specs/pulsar_admin_api_openapi_spec.yaml`.

4. Generate the client code

       make generate

5. Build the generated sources

       make build
