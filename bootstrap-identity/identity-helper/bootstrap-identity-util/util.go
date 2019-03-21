package util

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/spf13/viper"
	"gopkg.in/jcmturner/gokrb5.v7/credentials"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

//should be directly mapped to config
type KerberosCredentialCacheBroker struct {
	PodInfoPath string
	KDCSerivceURL string
	Krb5ConfURL string
	Krb5Path string
	FunctionalIds []string
	JWTPath string
}


type TokenServiceResponse struct {
	KerberosCredentialCache string
}

type KRB5ConfServiceResponse struct {
	Krb5Conf string
}

type KerberosCredentialCache struct {
	KCC *credentials.CCache
	FID string
}

func NewKerberosCredentialCacheBroker() *KerberosCredentialCacheBroker {

	fmt.Println("start reading the configuration")
	viper.SetConfigName("config")
	viper.AddConfigPath("./bootstrap-identity-util/config")

	if err := viper.ReadInConfig(); err != nil{
		panic(fmt.Errorf("Fatal error config file: %s \n", err))
	}
	podInfoLocation := viper.GetString("podInfoPath")
	tokenServiceURL := viper.GetString("kdcServiceURL")
	krb5ConfigURL := viper.GetString("krb5ConfURL")
	krb5OutputPath := viper.GetString("krb5Path")
	jwtPath := viper.GetString("jwtPath")

	if podInfoLocation=="" || tokenServiceURL=="" || krb5OutputPath=="" || jwtPath=="" || krb5ConfigURL==""{
		panic("Configuration not found!")
	}

	fmt.Println("reading pod info")
	viper.SetConfigType("properties")
	viper.SetConfigFile(podInfoLocation)

	if error := viper.ReadInConfig(); error != nil {
		panic(fmt.Errorf("Error reading pod info from [%s]: %s \n", podInfoLocation, error))
	}

	var functionalIds = viper.GetString("functionalIds")
	if functionalIds=="" {
		panic("No functional ids provided. There is nothing the identity helper can do for this app")
	}

	//TODO: all this mapping can be avoided by using viper features
	broker := new(KerberosCredentialCacheBroker)
	broker.PodInfoPath = podInfoLocation
	broker.KDCSerivceURL = tokenServiceURL
	broker.Krb5Path = krb5OutputPath
	broker.JWTPath = jwtPath
	broker.Krb5ConfURL = krb5ConfigURL

	broker.generateKRB5ConfFile()

	functionalIds = strings.Replace( functionalIds,"\"", "", -1)
	broker.FunctionalIds = strings.Split(functionalIds, ",")
	var functionalIdList [] string
	for _, id := range broker.FunctionalIds{
		functionalIdList = append(functionalIdList, strings.Trim(id, " "))
	}
	broker.FunctionalIds = functionalIdList
	return broker
}

func (broker *KerberosCredentialCacheBroker) generateKRB5ConfFile(){

	fmt.Println("Generating the krb5.conf file")

	if response, err := http.Get(broker.Krb5ConfURL); err != nil {
		panic(fmt.Errorf("Unable to fetch krb5.conf data from [%s] %s\n", broker.Krb5ConfURL, err))
	} else {
		data, _ := ioutil.ReadAll(response.Body)

		var krb5ConfResp KRB5ConfServiceResponse
		json.Unmarshal(data, &krb5ConfResp)
		if dec, err := base64.StdEncoding.DecodeString(string(krb5ConfResp.Krb5Conf));err!=nil{
			panic(fmt.Errorf("Unable to decode krb5.conf data from [%s] %s\n", broker.Krb5ConfURL, err))
		} else {

			os.MkdirAll(broker.Krb5Path, os.ModePerm)
			if f, err := os.Create(filepath.Join(broker.Krb5Path, "krb5.conf")); err!=nil{

			} else{
				defer f.Close()

				if _, err := f.Write(dec); err != nil {
					panic(err)
				}
				if err := f.Sync(); err != nil {
					panic(err)
				}
			}
		}
	}
}

func (broker *KerberosCredentialCacheBroker) ReadCredentials()  []*KerberosCredentialCache {

	var toReturn []*KerberosCredentialCache
	files, _ := ioutil.ReadDir(broker.Krb5Path)
	for _, f := range files {
		if f.IsDir() {
			kccFile := filepath.Join(broker.Krb5Path, f.Name(), "krb5cc")
			ccache, _ := credentials.LoadCCache(kccFile)
			toReturn = append(toReturn, &KerberosCredentialCache{KCC:ccache, FID:f.Name()})
		}
	}
	return toReturn
}

func (broker *KerberosCredentialCacheBroker) BrokerCredentialCacheForFID(functionalId string) *credentials.CCache{

	fmt.Printf("Generating the kcc functional id for FID: [%s]\n", functionalId)
	jwtContent, _ := ioutil.ReadFile(broker.JWTPath)
	values := map[string]string{"jwt": string(jwtContent), "functionalId": functionalId}
	jsonValue, _ := json.Marshal(values)

	//
	if response, err := http.Post(broker.KDCSerivceURL, "application/json", bytes.NewBuffer(jsonValue)); err != nil {
		fmt.Errorf("Unable to broker KCC for functional id [%s] from [%s] %s\n", functionalId, broker.KDCSerivceURL, err)
		return nil
	} else {
		if data, err := ioutil.ReadAll(response.Body); err!=nil {
			//TODO: introduce "real" error handling once the service api is established
			fmt.Errorf("error reading kcc response for functional id: [%s}\n", functionalId, err)
			return nil
		} else {
			var tokenServiceResponse TokenServiceResponse
			json.Unmarshal(data, &tokenServiceResponse)


			if dec, err := base64.StdEncoding.DecodeString(string(tokenServiceResponse.KerberosCredentialCache)); err!=nil {
				fmt.Errorf("error decoding base64 string for functional id: [%s}\n", functionalId, err)
				return nil
			} else {
				functionalIdKccPath := filepath.Join(broker.Krb5Path, functionalId)

				os.MkdirAll(functionalIdKccPath, os.ModePerm)
				ccPath := filepath.Join(functionalIdKccPath, "krb5cc")
				if f, err := os.Create(ccPath); err!=nil {
					fmt.Errorf("Unable to create krb5cc directory: [%s]\n", ccPath, err)
					return nil
				} else {
					defer f.Close()
					if _, err := f.Write(dec); err != nil {
						fmt.Errorf("Unable to write credential cache: [%s]\n", f, err)
						return nil
					}
					if err := f.Sync(); err != nil {
						fmt.Errorf("sync error with credential cache file: [%s]\n", f, err)
						return nil
					}
					fmt.Printf("KCC for FID [%s] can be found in [%s]\n", functionalId, f.Name())
					ccache, _ := credentials.LoadCCache(f.Name())
					return ccache
				}
			}
		}
	}
}

func (broker *KerberosCredentialCacheBroker) BrokerCredentialCache(){

	fmt.Println("reading JWT token")

	for _, functionalId := range broker.FunctionalIds {
		broker.BrokerCredentialCacheForFID(functionalId)
	}
}
