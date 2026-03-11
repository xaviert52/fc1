package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
)

type InviteRequest struct {
	InviterID string `json:"inviter_id"`
	Email     string `json:"email"`
	CompanyID string `json:"company_id"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Telefono  string `json:"telefono"`
	DNI       string `json:"dni"`
}

// handleCreateInvite procesa la creación en Kratos y Keto
func handleCreateInvite(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req InviteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	kratosAdmin := os.Getenv("KRATOS_ADMIN_URL")
	ketoWrite := os.Getenv("KETO_WRITE_URL")

	// 1. Crear Identidad en Kratos
	identityPayload := map[string]interface{}{
		"schema_id": "default",
		"traits": map[string]interface{}{
			"email":     req.Email,
			"telefono":  req.Telefono,
			"name":      map[string]string{"first": req.FirstName, "last": req.LastName},
			"dni":       req.DNI,
			"companies": []string{req.CompanyID},
		},
	}
	identityBody, _ := json.Marshal(identityPayload)
	resp, err := http.Post(kratosAdmin+"/admin/identities", "application/json", bytes.NewBuffer(identityBody))
	if err != nil || resp.StatusCode >= 300 {
		http.Error(w, "Falló creación en Kratos", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	var kratosRes map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&kratosRes)
	newUserID := kratosRes["id"].(string)

	// 2. Crear Relación en Keto (newUserID reporta a InviterID)
	ketoPayload := map[string]string{
		"namespace":  "User",
		"object":     newUserID,
		"relation":   "manager",
		"subject_id": req.InviterID,
	}
	ketoBody, _ := json.Marshal(ketoPayload)
	reqKeto, _ := http.NewRequest(http.MethodPut, ketoWrite+"/admin/relation-tuples", bytes.NewBuffer(ketoBody))
	reqKeto.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	client.Do(reqKeto)

	// 3. Generar Link de Invitación
	recoveryPayload := map[string]string{"identity_id": newUserID}
	recoveryBody, _ := json.Marshal(recoveryPayload)
	recResp, _ := http.Post(kratosAdmin+"/admin/recovery/link", "application/json", bytes.NewBuffer(recoveryBody))
	defer recResp.Body.Close()

	var recData map[string]interface{}
	json.NewDecoder(recResp.Body).Decode(&recData)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message":     "Usuario B2B creado exitosamente",
		"new_user_id": newUserID,
		"invite_link": recData["recovery_link"],
	})
}

// handleGetHierarchy devuelve la lista de subordinados
func handleGetHierarchy(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extraer userID de la URL manualmente (ej: /core/hierarchy?user_id=123)
	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		// Intento de extraer del path si viene como /core/hierarchy/123
		parts := strings.Split(r.URL.Path, "/")
		if len(parts) > 3 {
			userID = parts[3]
		} else {
			http.Error(w, "user_id is required", http.StatusBadRequest)
			return
		}
	}

	ketoRead := os.Getenv("KETO_READ_URL")
	subordinates := getSubordinatesRecursive(ketoRead, userID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"hierarchy_root": userID,
		"subordinates":   subordinates,
	})
}

func getSubordinatesRecursive(ketoReadURL, managerID string) []string {
	url := fmt.Sprintf("%s/relation-tuples?namespace=User&relation=manager&subject_id=%s", ketoReadURL, managerID)
	resp, err := http.Get(url)
	if err != nil {
		return []string{}
	}
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)
	var result map[string]interface{}
	json.Unmarshal(body, &result)

	tuples, ok := result["relation_tuples"].([]interface{})
	if !ok {
		return []string{}
	}

	var directSubordinates []string
	for _, t := range tuples {
		tupleMap := t.(map[string]interface{})
		subID := tupleMap["object"].(string)
		directSubordinates = append(directSubordinates, subID)

		nested := getSubordinatesRecursive(ketoReadURL, subID)
		directSubordinates = append(directSubordinates, nested...)
	}

	return directSubordinates
}
