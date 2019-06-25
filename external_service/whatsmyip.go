package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"
)

const (
	API_ENDPOINT = "https://api.ipify.org/?format=json"
	PORT         = 8080
)

func getData() string {
	response, err := http.Get(API_ENDPOINT)
	if err != nil {
		return "Request to " + API_ENDPOINT + " failed :("
	}
	defer response.Body.Close()
	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return "Reading response failed :("
	}
	result := map[string]string{}
	err = json.Unmarshal(body, &result)
	if err != nil {
		return "Parsing response failed :("
	}
	return result["ip"]
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, getData())
}

func main() {
	http.HandleFunc("/", handler)
	log.Fatal(http.ListenAndServe(":"+strconv.FormatInt(PORT, 10), nil))
}
