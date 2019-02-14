package main

import (
	"fmt"
	"net/http"
)

func main() {
	fmt.Println("Hello Application Container")
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello Application, you've requested: %s\n", r.URL.Path)
	})

	http.ListenAndServe(":8080", nil)
}
