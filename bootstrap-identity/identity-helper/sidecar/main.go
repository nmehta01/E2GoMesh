package main

import (
	"fmt"
	"github.com/E2GoMesh/bootstrap-identity/identity-helper/bootstrap-identity-util"
	"time"
)

func main() {

	fmt.Println("Identity helper sidecar looking for kerberos credential cache(s) to maintain")

	broker := util.NewKerberosCredentialCacheBroker()

	toReturn := broker.ReadCredentials()

	for _, cred := range toReturn {
		go manageCredential(cred, broker)
	}
	select {}
}

func manageCredential(kcc *util.KerberosCredentialCache, broker *util.KerberosCredentialCacheBroker) {

	for {
		broker.BrokerCredentialCacheForFID(kcc.FID)
		fmt.Printf("Done refreshing the functional id for %s. Now sleeping for 2 mins\n", kcc.FID)
		time.Sleep(2 * time.Minute)
	}

}
