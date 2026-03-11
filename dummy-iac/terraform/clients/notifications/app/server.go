package main

import (
	"log"
	"net/http"
	"time"
)

func startServer() {
	mux := http.NewServeMux()

	// Rutas originales de notificaciones y autenticación
	mux.HandleFunc("/events", handleEvents)
	mux.HandleFunc("/api/v1/auth/verify", verifyAccess)

	// ----- NUEVAS RUTAS CORE API (B2B2C MAGIC LINKS POKA-YOKE) -----

	// Paso 1: Generar link cifrado
	mux.HandleFunc("/core/invites/generate", handleGenerateInvite)

	// Paso 2: Consolidar tras registro
	mux.HandleFunc("/core/invites/redeem", handleRedeemInvite)

	// Auditoría: Árbol en cascada
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
