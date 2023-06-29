package main

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
