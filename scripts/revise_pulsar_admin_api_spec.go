package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"regexp"
	"strings"
)

const (
	progName = "revise_pulsar_admin_api_spec.go"
)

var (
	// endpointMatch tries to match an endpoint definition, looks like "/my/path-to-stuff/foo"
	endpointMatch = `\s+"(/[\w-{}]+)+": {`
	endpointRegex = regexp.MustCompile(endpointMatch)

	// nonPersistentTopicEndpointMatch only matches an endpoint for a non-persistent topic
	nonPersistentTopicEndpointMatch = `\s+"/non-persistent/\{tenant\}/\{namespace\}/.+": {`
	nonPersistentTopicEndpointRegex = regexp.MustCompile(nonPersistentTopicEndpointMatch)

	// matchNonPersistentTopicEndpointExpr only matches an endpoint for a non-persistent topic
	operationIDMatch = `\s+"operationId": "(\w+)",`
	operationIDRegex = regexp.MustCompile(operationIDMatch)

	// expireMessagesTimeEndpointMatch matches a specific endpoint which must be revised to avoid duplicate operation ID
	expireMessagesTimeEndpointMatch = `\s+"/(non-)?persistent/\{tenant\}/\{namespace\}/\{topic\}/subscription/\{subName\}/expireMessages/\{expireTimeInSeconds\}": {`
	expireMessagesTimeEndpointRegex = regexp.MustCompile(expireMessagesTimeEndpointMatch)

	matchSchemasWithVersionEndpoint = `\s+"/schemas/\{tenant\}/\{namespace\}/\{topic\}/schema/\{version\}": {`
	regexSchemasWithVersionEndpoint = regexp.MustCompile(matchSchemasWithVersionEndpoint)

	matchBrokersByClusterEndpoint = `\s+"/brokers/\{cluster\}": {`
	regexBrokersByClusterEndpoint = regexp.MustCompile(matchBrokersByClusterEndpoint)
)

func usage() {
	fmt.Printf("usage: go run %v input_file output_file\n", progName)
}

func main() {
	if len(os.Args) < 3 {
		fmt.Println("missing expected arguments")
		usage()
		os.Exit(1)
	}

	inputFilename := os.Args[1]
	outputFilename := os.Args[2]
	inputFile, err := os.Open(inputFilename)

	if err != nil {
		log.Fatal(err)
	}
	defer inputFile.Close()
	outputFile, err := os.Create(outputFilename)
	if err != nil {
		log.Fatal(err)
	}
	defer inputFile.Close()

	inNonPersistentTopic := false
	inExpireMessageEndpoint := false
	inSchemaByVersionEndpoint := false
	inBrokersByClusterEndpoint := false

	scanner := bufio.NewScanner(inputFile)
	writer := bufio.NewWriter(outputFile)
	for scanner.Scan() {
		nextLine := scanner.Bytes()

		if endpointRegex.Match(nextLine) {
			// In an endpoint definition, so check for the endpoints we want to modify
			inNonPersistentTopic = nonPersistentTopicEndpointRegex.Match(nextLine)
			inExpireMessageEndpoint = expireMessagesTimeEndpointRegex.Match(nextLine)
			inSchemaByVersionEndpoint = regexSchemasWithVersionEndpoint.Match(nextLine)
			inBrokersByClusterEndpoint = regexBrokersByClusterEndpoint.Match(nextLine)
		}

		nextLineOut := string(nextLine)
		if operationIDRegex.Match([]byte(nextLine)) {
			if inExpireMessageEndpoint {
				nextLineOut = strings.Replace(nextLineOut, "PersistentTopics_expireTopicMessages", "PersistentTopics_expireTopicMessages_expireTime", 1)
			}
			if inNonPersistentTopic {
				nextLineOut = strings.Replace(nextLineOut, "\"operationId\": \"PersistentTopics", "\"operationId\": \"NonPersistentTopics", 1)
			}
			if inSchemaByVersionEndpoint {
				nextLineOut = strings.Replace(nextLineOut, "SchemasResource_getSchema", "SchemasResource_getSchemaByVersion", 1)
			}
			if inBrokersByClusterEndpoint {
				nextLineOut = strings.Replace(nextLineOut, "BrokersBase_getActiveBrokers", "BrokersBase_getActiveBrokersByCluster", 1)
			}
		}

		_, err = writer.WriteString(nextLineOut + "\n")
		if err != nil {
			log.Fatalf("unexpected error occured while writing to output file: %v", err)
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
	if err = writer.Flush(); err != nil {
		log.Fatal(err)
	}

}
