package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

func main() {
	fmt.Println("Hello Init Container")
	callRestAPI()
}
func callRestAPI() {
	fmt.Println("Starting the application...")
	jsonData := map[string]string{"firstname": "Nic", "lastname": "Raboy"}
	jsonValue, _ := json.Marshal(jsonData)
	response, err := http.Post("https://httpbin.org/post", "application/json", bytes.NewBuffer(jsonValue))
	if err != nil {
		fmt.Printf("The HTTP request failed with error %s\n", err)
	} else {
		data, _ := ioutil.ReadAll(response.Body)
		fmt.Println(string(data))
		fmt.Println("************Rest call is successfull************")
	}
	fmt.Println("Terminating the application...")
}
