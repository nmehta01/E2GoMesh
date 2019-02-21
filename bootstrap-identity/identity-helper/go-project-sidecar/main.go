package main

import (
	"fmt"
	"net/http"
)

func main() {
	fmt.Println("Hello Sidecar Container")
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello Side Car, you've requested: %s\n", r.URL.Path)
	})

	http.ListenAndServe(":8090", nil)
}
