package main

import (
	"github.com/gorilla/mux"
	"io/ioutil"
	"net/http"
	"fmt"
	"os"
    	"log"
  	"encoding/pem"
 	"crypto/rsa"
   	"crypto/x509"
    	"bytes"
     	 b64 "encoding/base64"
     	"math/big"

)

func check(e error) {
	if e != nil {
		panic(e)
	}
}


func decodeKeys() string {

    var pubKEY string
    //pubKEY  =  os.Getenv("PUBLIC_KEY")
    pubKEY, ok  :=  os.LookupEnv("PUBLIC_KEY")
     if ok ==false {
	     log.Fatal("Enviornment variable for Public key not set")
     }
    rootPEM, err := ioutil.ReadFile(pubKEY)
     if err != nil {
        log.Fatal(err)
    }

    block, _ := pem.Decode([]byte(rootPEM))
    var cert* x509.Certificate
    cert, _ = x509.ParseCertificate(block.Bytes)
    rsaPublicKey := cert.PublicKey.(*rsa.PublicKey)
    exponent := big.NewInt(int64(rsaPublicKey.E)) 
    n := b64.RawURLEncoding.EncodeToString([]byte((rsaPublicKey.N).Bytes()))
    e := b64.RawURLEncoding.EncodeToString([]byte((exponent).Bytes()))

    publicKeyDer, err := x509.MarshalPKIXPublicKey(rsaPublicKey)
    if err != nil {
        log.Fatal(err)
    }
    pubKeyBlock := pem.Block{
        Type:    "PUBLIC KEY",
        Headers: nil,
        Bytes:   publicKeyDer,
    }
    pubKeyPem := string(pem.EncodeToMemory(&pubKeyBlock))
    myString := []byte(pubKeyPem)    
    lines1 := bytes.Replace(myString,[]byte("-----BEGIN PUBLIC KEY-----\n"), []byte(""),1)
    lines2 := bytes.Replace(lines1,[]byte("\n-----END PUBLIC KEY-----\n"), []byte(""),1)

    output := fmt.Sprintf("{\"kty\":\" RSA\",\n  \"n\":\"%s\",\n  \"e\":\"%s\",\n  \"x5t\":\"%s\"\n }", n, e, string(lines2))
//    fmt.Println(output)
    return output
 }


func GetKeys(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, decodeKeys())
}


// main function to boot up everything
func main() {
	router := mux.NewRouter()
	router.HandleFunc("/keys", GetKeys).Methods("GET")
	log.Fatal(http.ListenAndServe(":8000", router))
}
