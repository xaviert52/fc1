package main

import (
	"encoding/json"
	"fmt"
	"net/http"
)

// Estructuras para decodificar las respuestas nativas de Ory
type KratosSession struct {
	Identity struct {
		ID string `json:"id"`
	} `json:"identity"`
}

type KetoResponse struct {
	Allowed bool `json:"allowed"`
}

// verifySignerAccess es el endpoint que APISIX consultará en cada petición
// Renombramos la función para que sea genérica
func verifyAccess(w http.ResponseWriter, r *http.Request) {
	// Leer el servicio que APISIX nos está enviando
	serviceName := r.URL.Query().Get("service")
	if serviceName == "" {
		http.Error(w, "Bad Request: No service specified", http.StatusBadRequest)
		return
	}

	authHeader := r.Header.Get("Authorization")
	cookieHeader := r.Header.Get("Cookie")
	reqKratos, _ := http.NewRequest("GET", "http://kratos:4433/sessions/whoami", nil)

	if cookieHeader != "" {
		reqKratos.Header.Set("Cookie", cookieHeader)
	} else if authHeader != "" {
		reqKratos.Header.Set("Authorization", authHeader)
	} else {
		http.Error(w, "Unauthorized: No session credentials", http.StatusUnauthorized)
		return
	}

	client := &http.Client{}
	respKratos, err := client.Do(reqKratos)
	if err != nil || respKratos.StatusCode != 200 {
		http.Error(w, "Unauthorized or session expired", http.StatusUnauthorized)
		return
	}
	defer respKratos.Body.Close()

	var session KratosSession
	json.NewDecoder(respKratos.Body).Decode(&session)
	userID := session.Identity.ID

	// 3. Keto: Validación de Autorización
	ketoURL := fmt.Sprintf("http://keto:4466/relation-tuples/check?namespace=Services&object=%s&relation=access&subject_id=%s", serviceName, userID)
	reqKeto, _ := http.NewRequest("GET", ketoURL, nil)

	respKeto, err := client.Do(reqKeto)
	if err != nil {
		http.Error(w, "Keto unreachable", http.StatusInternalServerError)
		return
	}
	defer respKeto.Body.Close()

	// Ory Keto responde 200 si es ALLOWED y 403 si es DENIED
	if respKeto.StatusCode == http.StatusOK {
		w.WriteHeader(http.StatusOK) // APISIX deja pasar
		return
	} else if respKeto.StatusCode == http.StatusForbidden {
		http.Error(w, fmt.Sprintf("Forbidden: No tienes privilegios para %s", serviceName), http.StatusForbidden) // APISIX bloquea
		return
	} else {
		http.Error(w, "Unexpected Keto response", http.StatusInternalServerError)
		return
	}

	var ketoRes KetoResponse
	json.NewDecoder(respKeto.Body).Decode(&ketoRes)

	// 4. Veredicto Final
	if ketoRes.Allowed {
		w.WriteHeader(http.StatusOK)
	} else {
		http.Error(w, fmt.Sprintf("Forbidden: No tienes privilegios para usar %s", serviceName), http.StatusForbidden)
	}
}
