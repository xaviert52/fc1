package main

import (
	"encoding/json"
	"log"
	"net/http"
)

func handleEvents(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	if r.Header.Get("Content-Type") != "application/json" {
		w.WriteHeader(http.StatusUnsupportedMediaType)
		return
	}

	var env Envelope
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()

	if err := decoder.Decode(&env); err != nil {
		log.Printf(`{"level":"error","msg":"invalid_json","error":"%s"}`, err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	if err := validateEnvelope(env); err != nil {
		log.Printf(
			`{"level":"error","msg":"invalid_envelope","error":"%s","event_id":"%s"}`,
			err,
			env.ID,
		)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	key := makeIdempotencyKey(
		env.Type,
		env.Data.IdentityID,
		env.Data.FlowID,
	)

	if idemCache.seen(key) {
		log.Printf(
			`{"level":"info","msg":"duplicate_event","type":"%s","event_id":"%s","identity_id":"%s","request_id":"%s"}`,
			env.Type,
			env.ID,
			env.Data.IdentityID,
			env.Trace.RequestID,
		)
		w.WriteHeader(http.StatusAccepted)
		return
	}

	log.Printf(
		`{"level":"info","msg":"event_received","type":"%s","event_id":"%s","identity_id":"%s","request_id":"%s"}`,
		env.Type,
		env.ID,
		env.Data.IdentityID,
		env.Trace.RequestID,
	)

	dispatchNotification(env)

	w.WriteHeader(http.StatusAccepted)
}
