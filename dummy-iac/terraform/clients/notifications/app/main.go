package main

import (
	"log"
	"net/http"
)

func main() {
	log.Println(`{"level":"info","msg":"notifications service starting"}`)

	initDB()

	http.HandleFunc("/events", handleEvents)
	// Asegúrate de que la ruta sea exactamente esta y apunte a verifyAccess
	http.HandleFunc("/api/v1/auth/verify", verifyAccess)

	startServer()
}
