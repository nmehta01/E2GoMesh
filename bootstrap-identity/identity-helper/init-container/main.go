package main

import (
	"github.com/E2GoMesh/bootstrap-identity/identity-helper/bootstrap-identity-util"
)

func main() {

	broker := util.NewKerberosCredentialCacheBroker()
	broker.BrokerCredentialCache()
}