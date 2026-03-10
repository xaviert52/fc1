package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

var db *sql.DB

func initDB() {
	// Lectura de variables de entorno (Inyectadas por Docker Compose)
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")
	dbHost := os.Getenv("DB_HOST")
	dbName := os.Getenv("DB_NAME")

	// Parámetros opcionales con valores por defecto seguros para la red interna
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}
	sslMode := os.Getenv("DB_SSLMODE")
	if sslMode == "" {
		sslMode = "disable"
	}

	// Validación de dependencias críticas antes de intentar la conexión
	if dbUser == "" || dbPass == "" || dbHost == "" || dbName == "" {
		log.Fatalf(`{"level":"fatal","msg":"db_config_error","error":"Faltan variables de entorno requeridas (DB_USER, DB_PASSWORD, DB_HOST, DB_NAME)"}`)
	}

	// Construcción dinámica de la cadena de conexión
	connStr := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
		dbUser, dbPass, dbHost, dbPort, dbName, sslMode)

	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf(`{"level":"fatal","msg":"db_open_failed","error":"%s"}`, err)
	}

	if err = db.Ping(); err != nil {
		log.Fatalf(`{"level":"fatal","msg":"db_ping_failed","error":"%s"}`, err)
	}
	log.Println(`{"level":"info","msg":"connected to pry_negocio db successfully"}`)
}

type InviteRecord struct {
	EmpresaID   string
	RolAsignado string
}

func processInviteToken(token string) (*InviteRecord, error) {
	var record InviteRecord
	var usado bool

	// 1. Busca el token
	query := `SELECT empresa_id, rol_asignado, usado FROM invitaciones WHERE token = $1`
	err := db.QueryRow(query, token).Scan(&record.EmpresaID, &record.RolAsignado, &usado)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("token no encontrado en BD")
		}
		return nil, err
	}

	// 2. Verifica si ya se usó
	if usado {
		return nil, fmt.Errorf("el token ya fue consumido anteriormente")
	}

	// 3. Quema el token (UPDATE)
	updateQuery := `UPDATE invitaciones SET usado = TRUE WHERE token = $1`
	_, err = db.Exec(updateQuery, token)
	if err != nil {
		return nil, fmt.Errorf("error al marcar token como usado: %v", err)
	}

	return &record, nil
}
