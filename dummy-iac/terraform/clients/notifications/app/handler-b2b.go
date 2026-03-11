package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

// InviteRequest es lo que nos envía el Backend Intermedio
type InviteRequest struct {
	InviterID string `json:"inviter_id" binding:"required"`
	Email     string `json:"email" binding:"required"`
	CompanyID string `json:"company_id" binding:"required"`
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name" binding:"required"`
	Telefono  string `json:"telefono" binding:"required"`
	DNI       string `json:"dni" binding:"required"`
}

// HandleCreateInvite crea la identidad, la relación en Keto y devuelve el link
func handleCreateInvite(c *gin.Context) {
	var req InviteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	kratosAdmin := os.Getenv("KRATOS_ADMIN_URL")
	ketoWrite := os.Getenv("KETO_WRITE_URL")

	// 1. Crear Identidad en Kratos (Admin API)
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
		c.JSON(500, gin.H{"error": "Falló creación en Kratos"})
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
	reqKeto, _ := http.NewRequest("PUT", ketoWrite+"/admin/relation-tuples", bytes.NewBuffer(ketoBody))
	reqKeto.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	client.Do(reqKeto) // Ejecutamos la inserción en Keto

	// 3. Generar Link de Invitación/Recuperación (Para que el usuario setee su clave)
	recoveryPayload := map[string]string{"identity_id": newUserID}
	recoveryBody, _ := json.Marshal(recoveryPayload)
	recResp, _ := http.Post(kratosAdmin+"/admin/recovery/link", "application/json", bytes.NewBuffer(recoveryBody))
	defer recResp.Body.Close()

	var recData map[string]interface{}
	json.NewDecoder(recResp.Body).Decode(&recData)

	c.JSON(200, gin.H{
		"message":     "Usuario B2B creado y jerarquía enlazada exitosamente",
		"new_user_id": newUserID,
		"invite_link": recData["recovery_link"], // El Backend Intermedio envía este link por correo
	})
}

// HandleGetHierarchy devuelve el árbol de subordinados en cascada para auditoría
func handleGetHierarchy(c *gin.Context) {
	rootUserID := c.Param("user_id")
	ketoRead := os.Getenv("KETO_READ_URL")

	subordinates := getSubordinatesRecursive(ketoRead, rootUserID)

	c.JSON(200, gin.H{
		"hierarchy_root": rootUserID,
		"subordinates":   subordinates,
	})
}

// Función recursiva para buscar en cascada quién reporta a quién
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

		// Magia B2B2C: Buscar a los subordinados de los subordinados (Cascada)
		nested := getSubordinatesRecursive(ketoReadURL, subID)
		directSubordinates = append(directSubordinates, nested...)
	}

	return directSubordinates
}
