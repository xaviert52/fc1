package main

import (
	"log"
	"net/http"
	"time"
)

func startServer() {
	mux := http.NewServeMux()

	// Registro de rutas existentes
	mux.HandleFunc("/events", handleEvents)
	mux.HandleFunc("/api/v1/auth/verify", verifyAccess)

	// ----- NUEVAS RUTAS CORE API (B2B2C POKA-YOKE) -----
	mux.HandleFunc("/core/invites", handleCreateInvite)

	// La ruta base. El handler se encargará de extraer el ID de la URL
	// Ej: GET /core/hierarchy/UUID-AQUI o GET /core/hierarchy?user_id=UUID
	mux.HandleFunc("/core/hierarchy/", handleGetHierarchy)

	server := &http.Server{
		Addr:              ":8080",
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Println(`{"level":"info","msg":"listening on :8080"}`)

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf(`{"level":"fatal","msg":"server failed","error":"%s"}`, err)
	}
}
