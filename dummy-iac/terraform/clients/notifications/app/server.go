package main

import (
	"log"
	"net/http"
	"time"
)

func startServer() {
	mux := http.NewServeMux()

	// Registro de rutas en el mux local
	mux.HandleFunc("/events", handleEvents)
	mux.HandleFunc("/api/v1/auth/verify", verifyAccess) // <--- Agregado aquí

	server := &http.Server{
		Addr:              ":8080",
		Handler:           mux, // Este mux ahora conoce ambas rutas
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Println(`{"level":"info","msg":"listening on :8080"}`)

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf(`{"level":"fatal","msg":"server failed","error":"%s"}`, err)
	}
}
