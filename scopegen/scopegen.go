package main

import (
	"bufio"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

func main() {
	inScope := flag.Bool("in", false, "generate in-scope domains")
	outScope := flag.Bool("os", false, "generate out-of-scope domains")
	filePath := flag.String("t", "", "path to file containing domain list")
	flag.Parse()

	if !(*inScope || *outScope) {
		fmt.Println("Please specify either -in or -os")
		os.Exit(1)
	}

	var input []byte
	var err error
	if *filePath == "" {
		input, err = ioutil.ReadAll(os.Stdin)
		if err != nil {
			fmt.Printf("Error reading from stdin: %v\n", err)
			os.Exit(1)
		}
	} else {
		input, err = ioutil.ReadFile(*filePath)
		if err != nil {
			fmt.Printf("Error reading file %s: %v\n", *filePath, err)
			os.Exit(1)
		}
	}

	var output []string
	scanner := bufio.NewScanner(strings.NewReader(string(input)))
	for scanner.Scan() {
		domain := scanner.Text()
		if *inScope {
			output = append(output, fmt.Sprintf(".*\\.%s$", strings.ReplaceAll(domain, ".", "\\.")))
		} else if *outScope {
			output = append(output, fmt.Sprintf("!.*%s$", strings.ReplaceAll(domain, ".", "\\.")))
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Printf("Error reading input: %v\n", err)
		os.Exit(1)
	}

	fmt.Println(strings.Join(output, "\n"))
}
