package main

import (
	"encoding/json"
	"log"
	"net/http"
        "os"
)

var port = "18080"

// Exists reports whether the named file or directory exists.
func Exists(name string) bool {
    if _, err := os.Stat(name); err != nil {
       if os.IsNotExist(err) {
          return false
       }
    }
    return true
}

func GetHealthinessStatus(w http.ResponseWriter, r *http.Request) {
    if Exists("/var/log/healthiness") {
      d1 := map[string]string{"healthStatus": "OK"}
      json.NewEncoder(w).Encode(d1)
    } else {
      d1 := map[string]string{"healthStatus": "NotOK"}
      json.NewEncoder(w).Encode(d1)
    }
}

func GetLivelinessStatus(w http.ResponseWriter, r *http.Request) {
    if Exists("/var/log/liveliness") {
      d2 := map[string]string{"isUP": "true"}
      json.NewEncoder(w).Encode(d2)
    } else {
      d2 := map[string]string{"isUP": "false"}
      json.NewEncoder(w).Encode(d2)
    }
}


func main() {
	http.HandleFunc("/v1/healthiness", GetHealthinessStatus)
	http.HandleFunc("/v1/liveliness", GetLivelinessStatus)
	log.Println("listening on ", port)
	err := http.ListenAndServe("0.0.0.0:"+port, nil)
	log.Println("Error while starting server", err)
}
